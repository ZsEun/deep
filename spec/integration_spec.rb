# Integration tests for complete blog visibility control workflow
# Validates: Requirements 4.4, 5.1, 5.2, 5.3, 6.1, 6.2

require 'spec_helper'

RSpec.describe 'Integration: Complete Workflow' do
  let(:site_dir) { File.join(__dir__, '..', '_site') }
  let(:main_index) { File.join(site_dir, 'index.html') }
  let(:deep_index) { File.join(site_dir, 'deep', 'index.html') }

  # Featured posts (featured: true)
  let(:wu_title) { '这些人，那些事' }
  let(:lee_title) { '鹿川有许多粪' }

  # Non-featured posts (featured: false)
  let(:language_title) { '语言和思维' }
  let(:hufflepuff_title) { '赫奇帕奇' }

  # Post with no featured field (defaults to false)
  let(:eileen_title) { '许子东细读张爱玲' }

  # Post HTML file paths (direct access)
  let(:wu_post) { File.join(site_dir, '读书', '2026', '03', '15', 'wu.html') }
  let(:lee_post) { File.join(site_dir, '读书', '2026', '03', '14', 'lee.html') }
  let(:language_post) { File.join(site_dir, '文化', '瞎想', '2020', '04', '15', 'language.html') }
  let(:hufflepuff_post) { File.join(site_dir, '瞎想', '哈利波特', '2016', '06', '24', 'Hufflepuff.html') }
  let(:eileen_post) { File.join(site_dir, '读书', '2024', '11', '25', 'Eileen-Chang.html') }

  describe 'Main site filtering (Req 6.1)' do
    let(:main_html) { File.read(main_index) }

    it 'contains featured post titles' do
      expect(main_html).to include(wu_title)
      expect(main_html).to include(lee_title)
    end

    it 'does NOT contain non-featured post titles' do
      expect(main_html).not_to include(language_title)
      expect(main_html).not_to include(hufflepuff_title)
    end

    it 'does NOT contain posts with no featured field' do
      expect(main_html).not_to include(eileen_title)
    end
  end

  describe 'Deep site completeness (Req 6.2)' do
    let(:deep_html) { File.read(deep_index) }

    it 'contains all featured post titles' do
      expect(deep_html).to include(wu_title)
      expect(deep_html).to include(lee_title)
    end

    it 'contains all non-featured post titles' do
      expect(deep_html).to include(language_title)
      expect(deep_html).to include(hufflepuff_title)
    end

    it 'contains posts with no featured field' do
      expect(deep_html).to include(eileen_title)
    end
  end

  describe 'URL routing (Req 5.1, 5.2)' do
    it 'main site index exists at root' do
      expect(File.exist?(main_index)).to be true
    end

    it 'deep site index exists at /deep/' do
      expect(File.exist?(deep_index)).to be true
    end
  end

  describe 'Direct post access (Req 5.3)' do
    it 'featured posts are accessible via direct URL' do
      expect(File.exist?(wu_post)).to be true
      expect(File.exist?(lee_post)).to be true
    end

    it 'non-featured posts are accessible via direct URL' do
      expect(File.exist?(language_post)).to be true
      expect(File.exist?(hufflepuff_post)).to be true
    end

    it 'posts with no featured field are accessible via direct URL' do
      expect(File.exist?(eileen_post)).to be true
    end
  end
end
