require 'fileutils'

TAGS_DIR = "tags"
FileUtils.rm_rf(TAGS_DIR)
FileUtils.mkdir_p(TAGS_DIR)

tags = []

Dir.glob("_posts/*.*") do |post|
  File.readlines(post).each do |line|
    # Handle tags
    if line =~ /^tags:\s*\[(.+)\]/
      tags += $1.split(",").map(&:strip)
    elsif line =~ /^tags:\s*$/
      # Multi-line tags
      idx = File.readlines(post).index(line)
      tags += File.readlines(post)[(idx+1)..-1]
                .take_while { |l| l =~ /^\s*-\s*/ }
                .map { |l| l.strip.gsub("- ", "") }
    end
    
    # Handle categories
    if line =~ /^categories:\s*\[(.+)\]/
      tags += $1.split(",").map(&:strip)
    elsif line =~ /^categories:\s*(.+)$/
      tags += [$1.strip]
    elsif line =~ /^categories:\s*$/
      # Multi-line categories
      idx = File.readlines(post).index(line)
      tags += File.readlines(post)[(idx+1)..-1]
                .take_while { |l| l =~ /^\s*-\s*/ }
                .map { |l| l.strip.gsub("- ", "") }
    end
  end
end

tags.uniq.each do |tag|
  slug = tag.downcase.strip.gsub(" ", "-")
  path = "#{TAGS_DIR}/#{slug}"
  FileUtils.mkdir_p(path)

  File.open("#{path}/index.md", "w") do |f|
    f.puts "---"
    f.puts "layout: tag"
    f.puts "title: \"Posts tagged with #{tag}\""
    f.puts "tag: #{tag}"
    f.puts "permalink: /tags/#{slug}/"
    f.puts "---"
  end
end
