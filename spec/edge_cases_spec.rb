# Unit tests for edge cases in blog visibility control
# Validates: Requirements 1.2, 1.3, 1.4, 2.1, 2.4, 3.1

require 'spec_helper'

RSpec.describe 'Edge Cases: Blog Visibility Control' do
  # Simulate Jekyll's Liquid `where` filter: site.posts | where: "featured", true
  def filter_featured(posts)
    posts.select { |post| post[:featured] == true }
  end

  # Deep site shows all posts (no filtering)
  def all_posts(posts)
    posts
  end

  # Build main site tag cloud (only from featured posts)
  def build_main_site_tag_cloud(posts)
    featured_posts = filter_featured(posts)
    tag_counts = {}
    featured_posts.each do |post|
      (post[:tags] || []).each do |tag|
        tag_counts[tag] = (tag_counts[tag] || 0) + 1
      end
    end
    tag_counts
  end

  # Build deep site tag cloud (from all posts)
  def build_deep_site_tag_cloud(posts)
    tag_counts = {}
    posts.each do |post|
      (post[:tags] || []).each do |tag|
        tag_counts[tag] = (tag_counts[tag] || 0) + 1
      end
    end
    tag_counts
  end

  context 'empty post collection (no posts)' do
    let(:posts) { [] }

    it 'main site returns no posts' do
      expect(filter_featured(posts)).to be_empty
    end

    it 'deep site returns no posts' do
      expect(all_posts(posts)).to be_empty
    end

    it 'main site tag cloud is empty' do
      expect(build_main_site_tag_cloud(posts)).to be_empty
    end

    it 'deep site tag cloud is empty' do
      expect(build_deep_site_tag_cloud(posts)).to be_empty
    end
  end

  context 'no featured posts (all posts have featured: false)' do
    let(:posts) do
      [
        { title: 'Post A', date: '2024-01-01', tags: ['ruby', 'rails'], featured: false },
        { title: 'Post B', date: '2024-02-01', tags: ['python'], featured: false },
        { title: 'Post C', date: '2024-03-01', tags: ['ruby', 'jekyll'] }
      ]
    end

    it 'main site returns no posts' do
      expect(filter_featured(posts)).to be_empty
    end

    it 'deep site returns all posts' do
      expect(all_posts(posts).size).to eq(3)
    end

    it 'main site tag cloud is empty' do
      expect(build_main_site_tag_cloud(posts)).to be_empty
    end

    it 'deep site tag cloud contains all tags' do
      cloud = build_deep_site_tag_cloud(posts)
      expect(cloud.keys).to contain_exactly('ruby', 'rails', 'python', 'jekyll')
      expect(cloud['ruby']).to eq(2)
      expect(cloud['rails']).to eq(1)
      expect(cloud['python']).to eq(1)
      expect(cloud['jekyll']).to eq(1)
    end
  end

  context 'all posts featured (all posts have featured: true)' do
    let(:posts) do
      [
        { title: 'Post X', date: '2024-04-01', tags: ['travel'], featured: true },
        { title: 'Post Y', date: '2024-05-01', tags: ['travel', 'food'], featured: true },
        { title: 'Post Z', date: '2024-06-01', tags: ['food', 'art'], featured: true }
      ]
    end

    it 'main site returns all posts' do
      expect(filter_featured(posts).size).to eq(3)
    end

    it 'deep site returns all posts' do
      expect(all_posts(posts).size).to eq(3)
    end

    it 'main site and deep site show the same posts' do
      expect(filter_featured(posts)).to eq(all_posts(posts))
    end

    it 'main site tag cloud matches deep site tag cloud' do
      expect(build_main_site_tag_cloud(posts)).to eq(build_deep_site_tag_cloud(posts))
    end

    it 'tag counts are correct' do
      cloud = build_main_site_tag_cloud(posts)
      expect(cloud['travel']).to eq(2)
      expect(cloud['food']).to eq(2)
      expect(cloud['art']).to eq(1)
    end
  end

  context 'single post in collection' do
    context 'when the single post is featured' do
      let(:posts) do
        [{ title: 'Only Post', date: '2024-07-01', tags: ['solo'], featured: true }]
      end

      it 'main site returns the post' do
        result = filter_featured(posts)
        expect(result.size).to eq(1)
        expect(result.first[:title]).to eq('Only Post')
      end

      it 'deep site returns the post' do
        expect(all_posts(posts).size).to eq(1)
      end

      it 'both tag clouds contain the tag with count 1' do
        expect(build_main_site_tag_cloud(posts)).to eq({ 'solo' => 1 })
        expect(build_deep_site_tag_cloud(posts)).to eq({ 'solo' => 1 })
      end
    end

    context 'when the single post is not featured' do
      let(:posts) do
        [{ title: 'Hidden Post', date: '2024-08-01', tags: ['secret'], featured: false }]
      end

      it 'main site returns no posts' do
        expect(filter_featured(posts)).to be_empty
      end

      it 'deep site returns the post' do
        result = all_posts(posts)
        expect(result.size).to eq(1)
        expect(result.first[:title]).to eq('Hidden Post')
      end

      it 'main site tag cloud is empty' do
        expect(build_main_site_tag_cloud(posts)).to be_empty
      end

      it 'deep site tag cloud contains the tag' do
        expect(build_deep_site_tag_cloud(posts)).to eq({ 'secret' => 1 })
      end
    end

    context 'when the single post has no featured field' do
      let(:posts) do
        [{ title: 'Default Post', date: '2024-09-01', tags: ['misc'] }]
      end

      it 'main site returns no posts (defaults to not featured)' do
        expect(filter_featured(posts)).to be_empty
      end

      it 'deep site returns the post' do
        expect(all_posts(posts).size).to eq(1)
      end

      it 'main site tag cloud is empty' do
        expect(build_main_site_tag_cloud(posts)).to be_empty
      end

      it 'deep site tag cloud contains the tag' do
        expect(build_deep_site_tag_cloud(posts)).to eq({ 'misc' => 1 })
      end
    end
  end
end
