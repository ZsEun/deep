# Unit tests for deployment configuration
# Validates: Requirements 4.1, 5.1, 5.4

require 'spec_helper'
require 'yaml'

RSpec.describe 'Deployment Configuration' do
  describe 'CNAME file' do
    let(:cname_path) { File.join(__dir__, '..', 'CNAME') }

    it 'exists in the repository root' do
      expect(File.exist?(cname_path)).to be true
    end

    it 'contains the correct custom domain' do
      content = File.read(cname_path).strip
      expect(content).to eq('www.zseun.org')
    end
  end

  describe '_config.yml' do
    let(:config_path) { File.join(__dir__, '..', '_config.yml') }
    let(:config) { YAML.load_file(config_path) }

    it 'exists in the repository root' do
      expect(File.exist?(config_path)).to be true
    end

    it 'has the correct url for the custom domain' do
      expect(config['url']).to eq('https://www.zseun.org')
    end

    it 'has baseurl set to empty string for root path serving' do
      expect(config['baseurl']).to eq('')
    end
  end
end
