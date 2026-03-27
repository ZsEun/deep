#!/usr/bin/env ruby
# frozen_string_literal: true

# Revert script: undoes the draft→published migration.
#
# Jekyll treats `published: false` specially — it removes those posts from
# site.posts entirely. We need to go back to using `draft: true` instead.
#
# Mapping:
#   published: false → replace with `draft: true`, remove the `published` line
#   published: true  → remove the `published` line (no change needed; omitting draft means published)
#   no published field → no change
#
# Idempotent: running twice produces the same result.
#   - If a post already has `draft: true` and no `published` field, it's left alone.

require "yaml"
require "date"

POSTS_DIR = File.expand_path("../_posts", __dir__)

changed = 0
skipped = 0

Dir.glob(File.join(POSTS_DIR, "*.markdown")).sort.each do |path|
  content = File.read(path)

  # Jekyll front matter is delimited by two "---" lines at the top of the file.
  unless content.match?(/\A---\s*\n/)
    skipped += 1
    next
  end

  parts = content.split(/^---\s*$/, 3)
  # parts[0] is empty (before first ---), parts[1] is YAML, parts[2] is body
  if parts.length < 3
    skipped += 1
    next
  end

  front_matter_str = parts[1]
  body = parts[2]

  begin
    fm = YAML.safe_load(front_matter_str, permitted_classes: [Date, Time]) || {}
  rescue Psych::SyntaxError
    warn "WARN: skipping #{path} — invalid YAML"
    skipped += 1
    next
  end

  # Nothing to do if there's no published field
  unless fm.key?("published")
    skipped += 1
    next
  end

  published_val = fm["published"]

  # Build new front matter lines
  new_lines = []
  front_matter_str.each_line do |line|
    stripped = line.strip

    # Remove published lines
    next if stripped.match?(/\Apublished\s*:/)

    new_lines << line
  end

  # If published was false, add draft: true (unless draft: true already exists)
  if published_val == false && !fm.key?("draft")
    insert_idx = new_lines.rindex { |l| l.strip.length > 0 }
    insert_idx = insert_idx ? insert_idx + 1 : new_lines.length
    new_lines.insert(insert_idx, "draft: true\n")
  end

  # If published was true, just remove the published line (already done above).
  # No need to add draft: false — omitting draft means published.

  new_front_matter = new_lines.join
  new_content = "---#{new_front_matter}---#{body}"

  File.write(path, new_content)
  changed += 1
  puts "Reverted: #{File.basename(path)}"
end

puts "\nDone. Changed: #{changed}, Skipped: #{skipped}"
