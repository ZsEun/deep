# Feature: blog-visibility-control, Property 3: Chronological Ordering
# **Validates: Requirements 2.2, 3.2**

require 'spec_helper'

RSpec.describe 'Property 3: Chronological Ordering' do
  # Simulate Jekyll's reverse chronological sorting (newest first)
  def sort_reverse_chronological(posts)
    posts.sort_by { |post| post[:date] }.reverse
  end

  # Simulate Jekyll's Liquid `where` filter: site.posts | where: "featured", true
  def filter_featured(posts)
    posts.select { |post| post[:featured] == true }
  end

  it 'unfiltered results (all posts) are in reverse chronological order' do
    property_of {
      size = range(2, 30)
      Array.new(size) do
        featured_value = choose(true, false, nil)
        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}",
          tags: Array.new(range(0, 4)) { sized(range(3, 10)) { string(:alpha) } }
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      sorted = sort_reverse_chronological(posts)

      # Verify dates are in descending order (newest first)
      sorted.each_cons(2) do |newer, older|
        expect(newer[:date] >= older[:date]).to be(true),
          "Posts not in reverse chronological order: '#{newer[:date]}' should be >= '#{older[:date]}'"
      end
    end
  end

  it 'filtered results (featured only) are in reverse chronological order' do
    property_of {
      size = range(2, 30)
      Array.new(size) do
        # Bias toward featured: true so we get enough featured posts to test ordering
        featured_value = choose(true, true, false, nil)
        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}",
          tags: Array.new(range(0, 4)) { sized(range(3, 10)) { string(:alpha) } }
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      featured_posts = filter_featured(posts)
      sorted_featured = sort_reverse_chronological(featured_posts)

      # Verify featured posts are in descending date order (newest first)
      sorted_featured.each_cons(2) do |newer, older|
        expect(newer[:date] >= older[:date]).to be(true),
          "Featured posts not in reverse chronological order: '#{newer[:date]}' should be >= '#{older[:date]}'"
      end
    end
  end
end
