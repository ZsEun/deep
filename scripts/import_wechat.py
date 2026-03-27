#!/usr/bin/env python3
"""
WeChat Post Importer - Import WeChat Official Account articles into Jekyll blog.

Usage:
    python scripts/import_wechat.py <wechat_url> [--slug SLUG] [--categories CATS]
                                                  [--no-featured] [--draft]
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import date
from typing import Optional
from urllib.parse import urlparse, parse_qs

import requests
from bs4 import BeautifulSoup
from markdownify import MarkdownConverter
from pypinyin import lazy_pinyin

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)

WX_FMT_MAP = {
    "jpeg": ".jpg",
    "png": ".png",
    "gif": ".gif",
    "webp": ".webp",
    "svg": ".svg",
}

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class ArticleMetadata:
    """Metadata extracted from a WeChat article."""
    title: str
    date: str  # YYYY-MM-DD


@dataclass
class MediaAsset:
    """A downloaded media asset."""
    original_url: str
    local_filename: str
    media_type: str  # "image" or "video"
    sequence: int


@dataclass
class FrontMatter:
    """Jekyll front matter fields."""
    layout: str = "post"
    title: str = ""
    date: str = ""
    categories: Optional[str] = None
    featured: bool = True
    draft: bool = False


# ---------------------------------------------------------------------------
# URL Validation
# ---------------------------------------------------------------------------

def validate_url(url: str) -> bool:
    """Return True if *url* matches ``https://mp.weixin.qq.com/s/...``."""
    return bool(re.match(r"^https://mp\.weixin\.qq\.com/s/.+", url))


# ---------------------------------------------------------------------------
# Article Fetcher
# ---------------------------------------------------------------------------

def fetch_article(url: str) -> str:
    """Fetch the HTML content of a WeChat article.

    Sends a browser-like User-Agent header.
    Raises ``SystemExit`` on network / HTTP errors.
    """
    try:
        resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=30)
        resp.raise_for_status()
        return resp.text
    except requests.ConnectionError as exc:
        print(f"Error: Network error – {exc}", file=sys.stderr)
        raise SystemExit(1)
    except requests.Timeout:
        print("Error: Request timed out.", file=sys.stderr)
        raise SystemExit(1)
    except requests.HTTPError as exc:
        code = exc.response.status_code if exc.response is not None else "unknown"
        print(f"Error: HTTP {code} – {exc}", file=sys.stderr)
        raise SystemExit(1)
    except requests.RequestException as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)


# ---------------------------------------------------------------------------
# HTML Parser / Metadata Extractor
# ---------------------------------------------------------------------------

def extract_metadata(html: str) -> dict:
    """Extract title and publish date from the full HTML page.

    Returns ``{"title": str, "date": str}`` where date is ``YYYY-MM-DD``.
    Falls back to today's date when publish date is not found.
    Exits with error when title is not found.
    """
    soup = BeautifulSoup(html, "html.parser")

    # --- title ---
    title = None
    og = soup.find("meta", property="og:title")
    if og and og.get("content"):
        title = og["content"].strip()
    if not title:
        el = soup.find(id="activity-name")
        if el:
            title = el.get_text(strip=True)
    if not title:
        print("Error: Could not find article title.", file=sys.stderr)
        raise SystemExit(1)

    # --- date ---
    pub_date = None
    el = soup.find(id="publish_time")
    if el:
        text = el.get_text(strip=True)
        m = re.search(r"(\d{4})-(\d{2})-(\d{2})", text)
        if m:
            pub_date = m.group(0)
    if not pub_date:
        og_date = soup.find("meta", property="article:published_time")
        if og_date and og_date.get("content"):
            m = re.search(r"(\d{4})-(\d{2})-(\d{2})", og_date["content"])
            if m:
                pub_date = m.group(0)
    if not pub_date:
        print("Warning: Publish date not found, using today's date.", file=sys.stderr)
        pub_date = date.today().strftime("%Y-%m-%d")

    return {"title": title, "date": pub_date}


def extract_body(html: str) -> BeautifulSoup:
    """Extract the article body from ``#js_content`` div.

    Removes scripts, styles, and non-article elements.
    Exits with error if ``#js_content`` is not found.
    """
    soup = BeautifulSoup(html, "html.parser")
    body = soup.find(id="js_content")
    if body is None:
        print("Error: Could not find #js_content – unexpected page structure.",
              file=sys.stderr)
        raise SystemExit(1)

    # Remove non-content elements
    for tag in body.find_all(["script", "style", "noscript"]):
        tag.decompose()

    return body


# ---------------------------------------------------------------------------
# Media Downloader
# ---------------------------------------------------------------------------

def determine_extension(url: str, response_headers: Optional[dict] = None) -> str:
    """Determine file extension from URL params, Content-Type, or URL path.

    Checks ``wx_fmt`` query parameter first, then Content-Type header,
    then URL path extension.  Returns a string like ``'.jpg'``.
    """
    # 1. wx_fmt parameter
    parsed = urlparse(url)
    params = parse_qs(parsed.query)
    wx_fmt = params.get("wx_fmt", [None])[0]
    if wx_fmt and wx_fmt.lower() in WX_FMT_MAP:
        return WX_FMT_MAP[wx_fmt.lower()]

    # 2. Content-Type header
    if response_headers:
        ct = response_headers.get("Content-Type", "")
        if "jpeg" in ct or "jpg" in ct:
            return ".jpg"
        if "png" in ct:
            return ".png"
        if "gif" in ct:
            return ".gif"
        if "webp" in ct:
            return ".webp"
        if "svg" in ct:
            return ".svg"
        if "mp4" in ct:
            return ".mp4"

    # 3. URL path extension
    path = parsed.path
    _, ext = os.path.splitext(path)
    if ext:
        return ext.lower()

    return ".jpg"  # safe default for WeChat images


def download_media(body: BeautifulSoup, slug: str, image_dir: str) -> dict:
    """Download images and videos from the article body.

    Returns ``{original_url: local_filename}`` mapping.
    """
    os.makedirs(image_dir, exist_ok=True)
    media_map: dict[str, str] = {}
    seq = 0

    # --- images ---
    for img in body.find_all("img"):
        src = img.get("data-src") or img.get("src")
        if not src or "mmbiz.qpic.cn" not in src:
            continue
        seq += 1
        try:
            resp = requests.get(src, headers={"User-Agent": USER_AGENT}, timeout=30)
            resp.raise_for_status()
            ext = determine_extension(src, dict(resp.headers))
            filename = f"{slug}_{seq}{ext}"
            filepath = os.path.join(image_dir, filename)
            with open(filepath, "wb") as f:
                f.write(resp.content)
            media_map[src] = filename
        except Exception as exc:
            print(f"Warning: Failed to download image {src} – {exc}", file=sys.stderr)

    # --- videos ---
    for video in body.find_all("video"):
        src = video.get("data-src") or video.get("src")
        if not src:
            continue
        seq += 1
        try:
            resp = requests.get(src, headers={"User-Agent": USER_AGENT}, timeout=60)
            resp.raise_for_status()
            ext = determine_extension(src, dict(resp.headers))
            if ext not in (".mp4", ".webm", ".ogg"):
                ext = ".mp4"
            filename = f"{slug}_{seq}{ext}"
            filepath = os.path.join(image_dir, filename)
            with open(filepath, "wb") as f:
                f.write(resp.content)
            media_map[src] = filename
        except Exception as exc:
            print(f"Warning: Failed to download video {src} – {exc}", file=sys.stderr)

    return media_map


# ---------------------------------------------------------------------------
# Markdown Converter
# ---------------------------------------------------------------------------

class WeChatConverter(MarkdownConverter):
    """Custom markdownify converter for WeChat article HTML."""

    def __init__(self, media_map=None, **kwargs):
        self.media_map = media_map or {}
        super().__init__(**kwargs)

    def convert_img(self, el, text, **kwargs):
        src = el.get("data-src") or el.get("src") or ""
        alt = el.get("alt") or "pic"
        filename = self.media_map.get(src)
        if filename:
            return f"![{alt}](/image/{filename})"
        return f"![{alt}]({src})"

    def convert_video(self, el, text, **kwargs):
        src = el.get("data-src") or el.get("src") or ""
        filename = self.media_map.get(src)
        if filename:
            return f'\n<video src="/image/{filename}" controls></video>\n'
        return f'\n<video src="{src}" controls></video>\n'


def _strip_wechat_attrs(body: BeautifulSoup) -> None:
    """Remove WeChat-specific style/class/data-* attributes in-place."""
    for tag in body.find_all(True):
        # Remove style
        if tag.has_attr("style"):
            del tag["style"]
        # Remove class
        if tag.has_attr("class"):
            del tag["class"]
        # Remove data-* attributes (except data-src which we need for images)
        to_remove = [a for a in tag.attrs if a.startswith("data-") and a != "data-src"]
        for a in to_remove:
            del tag[a]


def convert_to_markdown(body: BeautifulSoup, media_map: dict) -> str:
    """Convert the article body HTML to Markdown.

    Strips WeChat styling, replaces CDN URLs with local paths,
    and uses markdownify with a custom converter.
    """
    _strip_wechat_attrs(body)
    converter = WeChatConverter(
        media_map=media_map,
        heading_style="atx",
        bullets="-",
        strip=["span"],
    )
    md = converter.convert(str(body))
    # Clean up excessive blank lines
    md = re.sub(r"\n{3,}", "\n\n", md)
    return md.strip() + "\n"


# ---------------------------------------------------------------------------
# Front Matter Generator
# ---------------------------------------------------------------------------

def generate_front_matter(title: str, date: str, categories: Optional[str] = None,
                          featured: bool = True, draft: bool = False) -> str:
    """Generate YAML front matter delimited by ``---``."""
    lines = [
        "---",
        "layout: post",
        f'title: "{title}"',
        f"date: {date}",
    ]
    if categories is not None:
        lines.append(f"categories: {categories}")
    lines.append(f"featured: {'true' if featured else 'false'}")
    lines.append(f"draft: {'true' if draft else 'false'}")
    lines.append("---")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Slug Generator
# ---------------------------------------------------------------------------

def generate_slug(title: str) -> str:
    """Convert a Chinese title to a pinyin-based slug.

    Steps: pypinyin → lowercase → replace non-alnum with hyphen →
    collapse hyphens → strip leading/trailing hyphens.
    Falls back to ``post-<timestamp>`` if result is empty.
    """
    pinyin_list = lazy_pinyin(title)
    raw = "".join(pinyin_list).lower()
    slug = re.sub(r"[^a-z0-9]+", "-", raw)
    slug = re.sub(r"-{2,}", "-", slug)
    slug = slug.strip("-")
    if not slug:
        slug = f"post-{int(time.time())}"
    return slug


# ---------------------------------------------------------------------------
# Post File Writer
# ---------------------------------------------------------------------------

def write_post(front_matter: str, content: str, date: str, slug: str,
               posts_dir: str) -> str:
    """Write the post file to *posts_dir* as ``YYYY-MM-DD-<slug>.markdown``.

    Prompts user for confirmation if the file already exists.
    Returns the path of the created file.
    """
    if not os.path.isdir(posts_dir):
        print(f"Error: Posts directory does not exist: {posts_dir}", file=sys.stderr)
        raise SystemExit(1)

    filename = f"{date}-{slug}.markdown"
    filepath = os.path.join(posts_dir, filename)

    if os.path.exists(filepath):
        print(f"Warning: File already exists: {filepath}")
        answer = input("Overwrite? [y/N] ").strip().lower()
        if answer != "y":
            print("Aborted – no files modified.")
            raise SystemExit(0)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(front_matter)
        f.write("\n")
        f.write(content)

    return filepath


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv=None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Import a WeChat article into the Jekyll blog '保持采样'."
    )
    parser.add_argument("url", help="WeChat article URL (https://mp.weixin.qq.com/s/...)")
    parser.add_argument("--slug", default=None,
                        help="Override the auto-generated slug")
    parser.add_argument("--categories", default=None,
                        help="Set the post categories")
    parser.add_argument("--no-featured", action="store_true",
                        help="Set featured: false (default is true)")
    parser.add_argument("--draft", action="store_true",
                        help="Set draft: true (default is false)")
    return parser.parse_args(argv)


# ---------------------------------------------------------------------------
# Main Pipeline
# ---------------------------------------------------------------------------

def main(argv=None):
    """Entry point – orchestrates the full import pipeline."""
    args = parse_args(argv)

    # Resolve directories relative to the script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)  # deep/
    posts_dir = os.path.join(base_dir, "_posts")
    image_dir = os.path.join(base_dir, "image")

    # 1. Validate URL
    if not validate_url(args.url):
        print("Error: Invalid WeChat article URL. "
              "Expected: https://mp.weixin.qq.com/s/...", file=sys.stderr)
        raise SystemExit(1)

    # 2. Fetch HTML
    print(f"Fetching article: {args.url}")
    html = fetch_article(args.url)

    # 3. Extract metadata
    meta = extract_metadata(html)
    print(f"Title: {meta['title']}")
    print(f"Date:  {meta['date']}")

    # 4. Extract body
    body = extract_body(html)

    # 5. Generate slug
    slug = args.slug if args.slug else generate_slug(meta["title"])
    print(f"Slug:  {slug}")

    # 6. Download media
    print("Downloading media assets...")
    media_map = download_media(body, slug, image_dir)
    print(f"Downloaded {len(media_map)} media asset(s).")

    # 7. Convert to Markdown
    md_content = convert_to_markdown(body, media_map)

    # 8. Generate front matter
    featured = not args.no_featured
    front_matter = generate_front_matter(
        title=meta["title"],
        date=meta["date"],
        categories=args.categories,
        featured=featured,
        draft=args.draft,
    )

    # 9. Write post
    filepath = write_post(front_matter, md_content, meta["date"], slug, posts_dir)
    print(f"\nDone! Post created: {filepath}")
    print(f"Media assets downloaded: {len(media_map)}")


if __name__ == "__main__":
    main()
