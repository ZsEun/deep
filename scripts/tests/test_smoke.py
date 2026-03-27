"""Smoke tests for import_wechat core functions."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from import_wechat import (
    validate_url, generate_slug, generate_front_matter,
    determine_extension, extract_metadata, extract_body,
    convert_to_markdown, parse_args,
)


def test_validate_url_valid():
    assert validate_url("https://mp.weixin.qq.com/s/abc123") is True
    assert validate_url("https://mp.weixin.qq.com/s/XyZ_456-789") is True


def test_validate_url_invalid():
    assert validate_url("") is False
    assert validate_url("https://example.com") is False
    assert validate_url("http://mp.weixin.qq.com/s/abc") is False
    assert validate_url("https://mp.weixin.qq.com/s/") is False


def test_generate_slug_chinese():
    slug = generate_slug("你好世界")
    assert slug == "nihaoshijie"
    assert slug.isascii()
    assert slug[0] != "-" and slug[-1] != "-"


def test_generate_slug_mixed():
    slug = generate_slug("Hello你好World")
    assert slug.isascii()
    assert "--" not in slug


def test_generate_front_matter_basic():
    fm = generate_front_matter("Test Title", "2024-01-15")
    assert fm.startswith("---\n")
    assert fm.endswith("---\n")
    assert "layout: post" in fm
    assert 'title: "Test Title"' in fm
    assert "date: 2024-01-15" in fm
    assert "featured: true" in fm
    assert "draft: false" in fm
    assert "categories" not in fm


def test_generate_front_matter_with_categories():
    fm = generate_front_matter("T", "2024-01-01", categories="Life")
    assert "categories: Life" in fm


def test_generate_front_matter_flags():
    fm = generate_front_matter("T", "2024-01-01", featured=False, draft=True)
    assert "featured: false" in fm
    assert "draft: true" in fm


def test_determine_extension_wx_fmt():
    assert determine_extension("https://mmbiz.qpic.cn/img?wx_fmt=jpeg") == ".jpg"
    assert determine_extension("https://mmbiz.qpic.cn/img?wx_fmt=png") == ".png"
    assert determine_extension("https://mmbiz.qpic.cn/img?wx_fmt=webp") == ".webp"
    assert determine_extension("https://mmbiz.qpic.cn/img?wx_fmt=gif") == ".gif"
    assert determine_extension("https://mmbiz.qpic.cn/img?wx_fmt=svg") == ".svg"


def test_determine_extension_content_type():
    assert determine_extension("https://example.com/img", {"Content-Type": "image/jpeg"}) == ".jpg"
    assert determine_extension("https://example.com/img", {"Content-Type": "image/png"}) == ".png"


def test_determine_extension_path():
    assert determine_extension("https://example.com/photo.png") == ".png"


def test_extract_metadata_og_title():
    html = '<html><head><meta property="og:title" content="My Title" /></head><body></body></html>'
    meta = extract_metadata(html)
    assert meta["title"] == "My Title"


def test_extract_metadata_activity_name():
    html = '<html><head></head><body><h2 id="activity-name">Fallback Title</h2></body></html>'
    meta = extract_metadata(html)
    assert meta["title"] == "Fallback Title"


def test_extract_metadata_publish_date():
    html = '<html><head><meta property="og:title" content="T" /></head><body><em id="publish_time">2024-03-15</em></body></html>'
    meta = extract_metadata(html)
    assert meta["date"] == "2024-03-15"


def test_extract_body_basic():
    html = '<html><body><div id="js_content"><p>Hello</p><script>bad</script></div></body></html>'
    body = extract_body(html)
    assert body is not None
    assert body.find("script") is None
    assert "Hello" in body.get_text()


def test_extract_body_missing():
    import pytest
    html = "<html><body><div>No content div</div></body></html>"
    with pytest.raises(SystemExit):
        extract_body(html)


def test_convert_to_markdown_strips_attrs():
    from bs4 import BeautifulSoup
    html = '<div id="js_content"><p style="color:red" class="wx" data-role="p">Text</p></div>'
    body = BeautifulSoup(html, "html.parser").find(id="js_content")
    md = convert_to_markdown(body, {})
    assert "style" not in md
    assert "class=" not in md
    assert "data-role" not in md
    assert "Text" in md


def test_convert_to_markdown_image_replacement():
    from bs4 import BeautifulSoup
    html = '<div id="js_content"><img data-src="https://mmbiz.qpic.cn/test.jpg" /></div>'
    body = BeautifulSoup(html, "html.parser").find(id="js_content")
    media_map = {"https://mmbiz.qpic.cn/test.jpg": "slug_1.jpg"}
    md = convert_to_markdown(body, media_map)
    assert "![pic](/image/slug_1.jpg)" in md


def test_convert_to_markdown_video():
    from bs4 import BeautifulSoup
    html = '<div id="js_content"><video src="https://example.com/v.mp4"></video></div>'
    body = BeautifulSoup(html, "html.parser").find(id="js_content")
    media_map = {"https://example.com/v.mp4": "slug_1.mp4"}
    md = convert_to_markdown(body, media_map)
    assert '<video src="/image/slug_1.mp4" controls></video>' in md


def test_parse_args_basic():
    args = parse_args(["https://mp.weixin.qq.com/s/abc"])
    assert args.url == "https://mp.weixin.qq.com/s/abc"
    assert args.slug is None
    assert args.categories is None
    assert args.no_featured is False
    assert args.draft is False


def test_parse_args_all_flags():
    args = parse_args([
        "https://mp.weixin.qq.com/s/abc",
        "--slug", "my-slug",
        "--categories", "Tech",
        "--no-featured",
        "--draft",
    ])
    assert args.slug == "my-slug"
    assert args.categories == "Tech"
    assert args.no_featured is True
    assert args.draft is True
