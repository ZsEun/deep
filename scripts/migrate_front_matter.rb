#!/usr/bin/env ruby
# frozen_string_literal: true

# Migration script: replaces `draft` front matter field with `published`.
#
# Mapping:
#   draft: true              → published: false  (draft line removed)
#   draft: false             → draft line removed (published defaults to true)
#   both published and draft → draft line removed, published kept as-is
#   no draft field           → no change
#
# Idempotent: running twice produces the same result.

require "yaml"
require "date"

POSTS_DIR = File.expand_path("../_posts", __dir__)

Dir.glob(File.join(POSTS_DIR, "*.markdown")).sort.each do |path|
  content = File.read(path)

  # Jekyll front matter is delimited by two "---" lines at the top of the file.
  unless content.match?(/\A---\s*\n/)
    next # no front matter — skip
  end

  parts = content.split(/^---\s*$/, 3)
  # parts[0] is empty (before first ---), parts[1] is YAML, parts[2] is body
  next if parts.length < 3

  front_matter_str = parts[1]
  body = parts[2]

  begin
    fm = YAML.safe_load(front_matter_str, permitted_classes: [Date, Time]) || {}
  rescue Psych::SyntaxError
    warn "WARN: skipping #{path} — invalid YAML"
    next
  end

  next unless fm.key?("draft")

  draft_val = fm["draft"]
  has_published = fm.key?("published")

  # Build new front matter lines, removing `draft` and optionally adding `published`.
  new_lines = []
  front_matter_str.each_line do |line|
    stripped = line.strip

    # Skip draft lines
    next if stripped.match?(/\Adraft\s*:/)

    # If draft was true and there's no existing published field,
    # insert `published: false` where draft used to be — but we handle
    # that after filtering, so just collect non-draft lines here.
    new_lines << line
  end

  # If draft was true and no published field exists, add published: false.
  if draft_val == true && !has_published
    # Insert `published: false` at a sensible position — after the last
    # known field line (before any trailing blank lines in front matter).
    insert_idx = new_lines.rindex { |l| l.strip.length > 0 }
    insert_idx = insert_idx ? insert_idx + 1 : new_lines.length
    new_lines.insert(insert_idx, "published: false\n")
  end

  new_front_matter = new_lines.join
  new_content = "---#{new_front_matter}---#{body}"

  File.write(path, new_content)
  puts "Migrated: #{File.basename(path)}"
end

puts "Done."
