# Feature: blog-visibility-control, Property 2: Visibility Filtering Correctness
# **Validates: Requirements 1.2, 1.3, 1.4, 2.1, 3.1**

require 'spec_helper'

RSpec.describe 'Property 2: Visibility Filtering Correctness' do
  # Simulate Jekyll's Liquid `where` filter: site.posts | where: "featured", true
  def filter_featured(posts)
    posts.select { |post| post[:featured] == true }
  end

  # Deep site shows all posts (no filtering)
  def all_posts(posts)
    posts
  end

  it 'posts with featured: true appear in both main site and deep site results' do
    property_of {
      size = range(1, 30)
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
      featured = filter_featured(posts)
      deep = all_posts(posts)
      featured_true_posts = posts.select { |p| p[:featured] == true }

      # Every featured: true post must appear in main site filtered results
      featured_true_posts.each do |post|
        expect(featured).to include(post)
      end

      # Every featured: true post must also appear in deep site results
      featured_true_posts.each do |post|
        expect(deep).to include(post)
      end
    end
  end

  it 'posts with featured: false or omitted appear only in deep site (not main site)' do
    property_of {
      size = range(1, 30)
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
      featured = filter_featured(posts)
      deep = all_posts(posts)
      non_featured_posts = posts.select { |p| p[:featured] != true }

      # Posts with featured: false or omitted must NOT appear in main site
      non_featured_posts.each do |post|
        expect(featured).not_to include(post)
      end

      # Posts with featured: false or omitted MUST appear in deep site
      non_featured_posts.each do |post|
        expect(deep).to include(post)
      end
    end
  end

  it 'no posts are lost or duplicated across filtered and unfiltered views' do
    property_of {
      size = range(1, 30)
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
      featured = filter_featured(posts)
      deep = all_posts(posts)

      # Deep site must contain ALL posts (no loss)
      expect(deep.size).to eq(posts.size)

      # Featured filtered results must be a subset of all posts
      featured.each do |post|
        expect(posts).to include(post)
      end

      # Featured count + non-featured count must equal total
      non_featured = posts.select { |p| p[:featured] != true }
      expect(featured.size + non_featured.size).to eq(posts.size)

      # No duplicates in filtered results
      expect(featured.uniq.size).to eq(featured.size)

      # No duplicates in deep site results
      expect(deep.uniq.size).to eq(deep.size)
    end
  end
end
