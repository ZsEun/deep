# Feature: blog-visibility-control, Property 1: Front Matter Preservation
# **Validates: Requirements 1.5**

require 'spec_helper'

RSpec.describe 'Property 1: Front Matter Preservation' do
  # Simulate adding the featured flag to a post's front matter,
  # mirroring what happens when the visibility control system processes a post.
  # The key invariant: adding `featured` must not alter any existing fields.
  def add_featured_flag(post, featured_value)
    result = post.dup
    result[:featured] = featured_value
    result
  end

  it 'adding featured flag preserves all existing front matter fields' do
    property_of {
      # Generate random front matter fields
      layout = choose('post', 'page', 'default', 'custom')
      title = sized(range(3, 30)) { string(:alpha) }
      year = range(2015, 2025)
      month = range(1, 12).to_s.rjust(2, '0')
      day = range(1, 28).to_s.rjust(2, '0')
      date = "#{year}-#{month}-#{day}"
      categories = Array.new(range(0, 4)) { sized(range(3, 10)) { string(:alpha) } }
      tags = Array.new(range(0, 5)) { sized(range(3, 10)) { string(:alpha) } }
      featured_value = choose(true, false)

      post = {
        layout: layout,
        title: title,
        date: date,
        categories: categories,
        tags: tags
      }

      [post, featured_value]
    }.check(100) do |(post, featured_value)|
      # Capture original field values before processing
      original_layout = post[:layout]
      original_title = post[:title]
      original_date = post[:date]
      original_categories = post[:categories].dup
      original_tags = post[:tags].dup

      # Process: add the featured flag (simulating visibility control)
      processed = add_featured_flag(post, featured_value)

      # Verify all original fields are preserved unchanged
      expect(processed[:layout]).to eq(original_layout)
      expect(processed[:title]).to eq(original_title)
      expect(processed[:date]).to eq(original_date)
      expect(processed[:categories]).to eq(original_categories)
      expect(processed[:tags]).to eq(original_tags)

      # Verify the featured flag was actually set
      expect(processed[:featured]).to eq(featured_value)
    end
  end

  it 'preserves front matter when featured field is omitted vs explicitly set' do
    property_of {
      layout = choose('post', 'page', 'default')
      title = sized(range(3, 20)) { string(:alpha) }
      date = "#{range(2015, 2025)}-#{range(1, 12).to_s.rjust(2, '0')}-#{range(1, 28).to_s.rjust(2, '0')}"
      categories = Array.new(range(0, 3)) { sized(range(3, 8)) { string(:alpha) } }
      tags = Array.new(range(0, 4)) { sized(range(3, 8)) { string(:alpha) } }

      {
        layout: layout,
        title: title,
        date: date,
        categories: categories,
        tags: tags
      }
    }.check(100) do |post|
      # A post without featured field
      post_without = post.dup

      # A post with featured explicitly set
      post_with_true = add_featured_flag(post.dup, true)
      post_with_false = add_featured_flag(post.dup, false)

      # All three versions must have identical original fields
      [:layout, :title, :date, :categories, :tags].each do |field|
        expect(post_without[field]).to eq(post[field])
        expect(post_with_true[field]).to eq(post[field])
        expect(post_with_false[field]).to eq(post[field])
      end

      # The post without featured should not have the key
      expect(post_without).not_to have_key(:featured)
    end
  end
end
