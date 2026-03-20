# Feature: blog-visibility-control, Property 4: Main Site Tag Cloud Filtering
# **Validates: Requirements 2.3**

require 'spec_helper'

RSpec.describe 'Property 4: Main Site Tag Cloud Filtering' do
  # Simulate the main site tag cloud generation from home.html:
  # 1. Filter posts to only featured: true
  # 2. Collect all tags from those featured posts
  # 3. Count occurrences of each tag
  def build_main_site_tag_cloud(posts)
    featured_posts = posts.select { |post| post[:featured] == true }

    tag_counts = {}
    featured_posts.each do |post|
      (post[:tags] || []).each do |tag|
        tag_counts[tag] = (tag_counts[tag] || 0) + 1
      end
    end

    tag_counts
  end

  it 'tag cloud contains only tags from featured posts' do
    property_of {
      size = range(1, 30)
      # Define a pool of possible tags so posts can share tags
      tag_pool = Array.new(range(2, 8)) { sized(range(3, 10)) { string(:alpha) } }.uniq
      tag_pool = ['defaulttag'] if tag_pool.empty?

      Array.new(size) do
        featured_value = choose(true, false, nil)
        num_tags = range(0, [4, tag_pool.size].min)
        post_tags = tag_pool.sample(num_tags)

        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}",
          tags: post_tags
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      tag_cloud = build_main_site_tag_cloud(posts)

      featured_posts = posts.select { |p| p[:featured] == true }
      all_featured_tags = featured_posts.flat_map { |p| p[:tags] || [] }.uniq

      # Every tag in the cloud must come from a featured post
      tag_cloud.keys.each do |tag|
        expect(all_featured_tags).to include(tag),
          "Tag '#{tag}' is in the tag cloud but not in any featured post"
      end

      # Every tag from featured posts must appear in the cloud
      all_featured_tags.each do |tag|
        expect(tag_cloud.keys).to include(tag),
          "Tag '#{tag}' is in a featured post but missing from the tag cloud"
      end
    end
  end

  it 'tag counts match the number of featured posts containing each tag' do
    property_of {
      size = range(1, 30)
      tag_pool = Array.new(range(2, 8)) { sized(range(3, 10)) { string(:alpha) } }.uniq
      tag_pool = ['defaulttag'] if tag_pool.empty?

      Array.new(size) do
        featured_value = choose(true, false, nil)
        num_tags = range(0, [4, tag_pool.size].min)
        post_tags = tag_pool.sample(num_tags)

        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}",
          tags: post_tags
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      tag_cloud = build_main_site_tag_cloud(posts)

      featured_posts = posts.select { |p| p[:featured] == true }

      # For each tag in the cloud, verify the count equals the number of
      # featured posts that contain that tag
      tag_cloud.each do |tag, count|
        expected_count = featured_posts.count { |p| (p[:tags] || []).include?(tag) }
        expect(count).to eq(expected_count),
          "Tag '#{tag}' has count #{count} but #{expected_count} featured posts contain it"
      end
    end
  end

  it 'tag cloud is empty when no posts are featured' do
    property_of {
      size = range(1, 20)
      Array.new(size) do
        featured_value = choose(false, nil)
        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}",
          tags: Array.new(range(1, 4)) { sized(range(3, 10)) { string(:alpha) } }
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      tag_cloud = build_main_site_tag_cloud(posts)

      # No featured posts means empty tag cloud
      expect(tag_cloud).to be_empty,
        "Tag cloud should be empty when no posts are featured, but got: #{tag_cloud}"
    end
  end
end
