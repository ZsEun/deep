#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks all posts in _posts/ and renames any whose filename date
# doesn't match the `date:` field in the front matter.

require "yaml"
require "date"
require "fileutils"

POSTS_DIR = File.expand_path("../_posts", __dir__)

renamed = 0
skipped = 0

Dir.glob(File.join(POSTS_DIR, "*.markdown")).sort.each do |path|
  basename = File.basename(path)

  # Extract date from filename: YYYY-MM-DD-slug.markdown
  match = basename.match(/\A(\d{4}-\d{2}-\d{2})-(.+)\.markdown\z/)
  unless match
    puts "SKIP (no date in filename): #{basename}"
    skipped += 1
    next
  end

  filename_date = match[1]
  slug = match[2]

  # Read front matter
  content = File.read(path)
  unless content.match?(/\A---\s*\n/)
    puts "SKIP (no front matter): #{basename}"
    skipped += 1
    next
  end

  parts = content.split(/^---\s*$/, 3)
  next if parts.length < 3

  begin
    fm = YAML.safe_load(parts[1], permitted_classes: [Date, Time]) || {}
  rescue Psych::SyntaxError => e
    puts "SKIP (invalid YAML): #{basename} — #{e.message}"
    skipped += 1
    next
  end

  unless fm.key?("date")
    puts "SKIP (no date field): #{basename}"
    skipped += 1
    next
  end

  # Normalize the front matter date to YYYY-MM-DD
  fm_date = case fm["date"]
            when Date, Time
              fm["date"].strftime("%Y-%m-%d")
            when String
              m = fm["date"].strip.match(/(\d{4}-\d{2}-\d{2})/)
              m ? m[1] : nil
            else
              nil
            end

  unless fm_date
    puts "SKIP (unparseable date): #{basename}"
    skipped += 1
    next
  end

  if filename_date == fm_date
    skipped += 1
    next
  end

  # Rename needed
  new_basename = "#{fm_date}-#{slug}.markdown"
  new_path = File.join(POSTS_DIR, new_basename)

  if File.exist?(new_path) && new_path != path
    puts "WARN: Target already exists, skipping: #{new_basename}"
    skipped += 1
    next
  end

  FileUtils.mv(path, new_path)
  renamed += 1
  puts "RENAMED: #{basename} -> #{new_basename}"
end

puts "\nDone. Renamed: #{renamed}, Skipped: #{skipped}"
