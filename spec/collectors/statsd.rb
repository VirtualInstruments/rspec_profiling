require "rspec_profiling/config"
require "rspec_profiling/collectors/statsd"

module RspecProfiling
    module Collectors
        describe Statsd do 
            before(:all) { described_class.install }
            after(:all)  { described_class.uninstall }
      
            describe "#insert" do
              let(:collector) { described_class.new }
              let(:result)    { collector.results.first }
      
                before do
                    collector.insert({
                        branch: "master",
                        commit_hash: "ABC123",
                        date: "Thu Dec 18 12:00:00 2012",
                        file: "/some/file.rb",
                        line_number: 10,
                        description: "Some spec",
                        time: 100,
                        status: :passed,
                        exception: "some issue",
                        query_count: 10,
                        query_time: 50,
                        request_count: 1,
                        request_time: 400
                    })
                end
            
                it "records a single result" do
                    puts "helloo"
                    expect(collector.results.count).to eq 1
                end
            end
        end
    end
end