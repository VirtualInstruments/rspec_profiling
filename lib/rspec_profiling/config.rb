require "rspec_profiling/vcs/git"
require "rspec_profiling/collectors/statsd"

module RspecProfiling
  def self.configure
    yield config
  end

  def self.config
    @config ||= OpenStruct.new({
      collector:  RspecProfiling::Collectors::Statsd,
      vcs:        RspecProfiling::VCS::Git,
      table_name: 'spec_profiling_results'
    })
  end
end
