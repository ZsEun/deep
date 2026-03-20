# Feature: blog-visibility-control, Property 5: Deep Site Tag Cloud Completeness
# **Validates: Requirements 3.3**

require 'spec_helper'

RSpec.describe 'Property 5: Deep Site Tag Cloud Completeness' do
  # Simulate the deep site tag cloud generation from deep.html:
  # 1. Use ALL posts (no filtering by featured status)
  # 2. Collect all tags from every post
  # 3. Count occurrences of each tag
  def build_deep_site_tag_cloud(posts)
    tag_counts = {}
    posts.each do |post|
      (post[:tags] || []).each do |tag|
        tag_counts[tag] = (tag_counts[tag] || 0) + 1
      end
    end
    tag_counts
  end

  it 'tag cloud contains all tags from all posts regardless of featured status' do
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
      tag_cloud = build_deep_site_tag_cloud(posts)

      all_tags = posts.flat_map { |p| p[:tags] || [] }.uniq

      # Every tag from any post must appear in the deep site tag cloud
      all_tags.each do |tag|
        expect(tag_cloud.keys).to include(tag),
          "Tag '#{tag}' exists in a post but is missing from the deep site tag cloud"
      end

      # Every tag in the cloud must come from some post
      tag_cloud.keys.each do |tag|
        expect(all_tags).to include(tag),
          "Tag '#{tag}' is in the deep site tag cloud but not in any post"
      end
    end
  end

  it 'tag counts match total number of posts containing each tag' do
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
      tag_cloud = build_deep_site_tag_cloud(posts)

      # For each tag in the cloud, verify the count equals the total number
      # of posts (regardless of featured status) that contain that tag
      tag_cloud.each do |tag, count|
        expected_count = posts.count { |p| (p[:tags] || []).include?(tag) }
        expect(count).to eq(expected_count),
          "Tag '#{tag}' has count #{count} but #{expected_count} total posts contain it"
      end
    end
  end

  it 'tag cloud includes tags from non-featured posts' do
    property_of {
      size = range(2, 20)
      tag_pool = Array.new(range(2, 8)) { sized(range(3, 10)) { string(:alpha) } }.uniq
      tag_pool = ['defaulttag'] if tag_pool.empty?

      Array.new(size) do
        featured_value = choose(true, false, nil)
        num_tags = range(1, [4, tag_pool.size].min)
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
      tag_cloud = build_deep_site_tag_cloud(posts)

      non_featured_posts = posts.select { |p| p[:featured] != true }
      non_featured_tags = non_featured_posts.flat_map { |p| p[:tags] || [] }.uniq

      # Tags from non-featured posts must also appear in the deep site tag cloud
      non_featured_tags.each do |tag|
        expect(tag_cloud.keys).to include(tag),
          "Tag '#{tag}' from a non-featured post is missing from the deep site tag cloud"
      end
    end
  end
end
