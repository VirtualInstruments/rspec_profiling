require 'rspec_profiling/config'
require 'rspec_profiling/collectors/statsd'

module RspecProfiling
  module Collectors
    describe Statsd do 
      before(:all) { described_class.install }
      after(:all)  { described_class.uninstall }
    
      describe '#insert' do
        let(:collector) { described_class.new }
        let(:result)  { collector.results.first }
    
        before do
          collector.insert({
            branch: 'master',
            commit_hash: 'ABC123',
            date: 'Thu Dec 18 12:00:00 2012',
            file: '/some/file.rb',
            line_number: 10,
            description: 'Some spec',
            time: 100,
            status: :passed,
            exception: 'some issue',
            query_count: 10,
            query_time: 50,
            request_count: 1,
            request_time: 400
          })
        end
      
        it 'records a single result' do
          expect(collector.results.count).to eq 1
        end

        it 'Converts test description to 8 character hash' do
          small = collector.formatDesc('test')
          expect(small.length).to eq(8)

          big = collector.formatDesc('test more strings with spaces_and_underscores')
          expect(big.length).to eq(8)
        end

        it 'Converts file path to use dot separator over forward slash' do 
          str = collector.formatFile('/staas/spec/test/some_test.rb')
          expect(str).to eq 'staas.spec.test.some_test'
        end
      end
    end
  end
end