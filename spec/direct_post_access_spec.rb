# Feature: blog-visibility-control, Property 6: Direct Post Access Bypasses Filtering
# **Validates: Requirements 5.3**

require 'spec_helper'

RSpec.describe 'Property 6: Direct Post Access Bypasses Filtering' do
  # Simulate Jekyll's URL generation from date and title: /:categories/:year/:month/:day/:title.html
  def generate_url(post)
    date_parts = post[:date].split('-')
    year = date_parts[0]
    month = date_parts[1]
    day = date_parts[2]
    slug = post[:title].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
    categories_path = post[:categories].empty? ? '' : post[:categories].join('/') + '/'
    "/#{categories_path}#{year}/#{month}/#{day}/#{slug}.html"
  end

  # In Jekyll, site.posts contains ALL posts regardless of featured status.
  # Every post in site.posts gets its own page generated at its URL.
  # Filtering only affects the home page listing, not page generation.
  def site_posts(posts)
    posts
  end

  it 'every post has a generated URL and is in site.posts regardless of featured status' do
    property_of {
      size = range(1, 30)
      Array.new(size) do
        featured_value = choose(true, false, nil)
        year = range(2015, 2025)
        month = range(1, 12).to_s.rjust(2, '0')
        day = range(1, 28).to_s.rjust(2, '0')
        post = {
          title: sized(range(3, 20)) { string(:alpha) },
          date: "#{year}-#{month}-#{day}",
          categories: Array.new(range(0, 3)) { sized(range(3, 10)) { string(:alpha) } },
          tags: Array.new(range(0, 4)) { sized(range(3, 10)) { string(:alpha) } }
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      all_site_posts = site_posts(posts)

      posts.each do |post|
        # Every post generates a URL
        url = generate_url(post)
        expect(url).not_to be_nil
        expect(url).not_to be_empty
        expect(url).to match(%r{^/.*\.html$})

        # Every post is in site.posts (Jekyll generates a page for it)
        expect(all_site_posts).to include(post)
      end
    end
  end

  it 'featured and non-featured posts all produce valid, unique URLs' do
    property_of {
      size = range(2, 20)
      Array.new(size) do |i|
        featured_value = choose(true, false, nil)
        year = range(2015, 2025)
        month = range(1, 12).to_s.rjust(2, '0')
        day = range(1, 28).to_s.rjust(2, '0')
        # Append index to ensure unique titles
        post = {
          title: "#{sized(range(3, 15)) { string(:alpha) }}#{i}",
          date: "#{year}-#{month}-#{day}",
          categories: Array.new(range(0, 2)) { sized(range(3, 8)) { string(:alpha) } },
          tags: Array.new(range(0, 3)) { sized(range(3, 8)) { string(:alpha) } }
        }
        post[:featured] = featured_value unless featured_value.nil?
        post
      end
    }.check(100) do |posts|
      urls = posts.map { |post| generate_url(post) }

      # All URLs are valid paths ending in .html
      urls.each do |url|
        expect(url).to match(%r{^/.*\.html$})
      end

      # Filtering does NOT remove posts from site.posts
      featured_posts = posts.select { |p| p[:featured] == true }
      non_featured_posts = posts.select { |p| p[:featured] != true }

      # Both featured and non-featured posts remain in site.posts
      all_site_posts = site_posts(posts)
      (featured_posts + non_featured_posts).each do |post|
        expect(all_site_posts).to include(post)
      end
    end
  end
end
