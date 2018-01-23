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
            date: Time.new,
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

        it 'Converts file path to use dot separator over forward slash' do 
          str = collector.format_file('/spec/test/some_test.rb')
          expect(str).to eq 'test.some_test'
        end

        it 'Correctly uses the max depth parameter to top tier' do 
          str = collector.format_file('/spec/test/shared/model/lib/controller/bulk_action.rb', 1)
          expect(str).to eq 'test.bulk_action'
        end

        it 'Correctly uses max depth parameter to bottom tier' do
          str = collector.format_file('/spec/test/shared/model/lib/controller/bulk_action.rb', 4)
          expect(str).to eq 'test.shared.model.lib.bulk_action'
        end
        
        it 'Creates a readable stamp from a long string' do
          str = collector.build_stamp('API There are long strings in the test description where it can be really length however we need a small but unique name', 101)
          expect(str).to eq '101_small_unique_name'
        end

        it 'Creates a readable stamp from a single word' do
          str = collector.build_stamp('API', 101)
          expect(str).to eq '101_API'
        end

        it 'Handles description with underscores and periods as part of the sentence' do
          str = collector.build_stamp('There/be\\dragons. Who_don\'t_play_by_the_rules', 202)
          expect(str).to eq '202_don\'t_play_rules'
        end

        it 'Creates a readable stamp from a three word sentence' do
          str = collector.build_stamp('There be dragons', 101)
          expect(str).to eq '101_There_be_dragons'
        end
      end
    end
  end
end