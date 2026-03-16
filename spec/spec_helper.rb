# Backup branch: backup-pre-visibility-control
# Pre-visibility-control commit: 32f736fc83b9a679e57c7988f22e87fc9aded0cd

require 'rspec'
require 'rantly'
require 'rantly/rspec_extensions'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
