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

        it 'Converts small description to 8 character hash' do
          small = collector.format_desc('test')
          expect(small.length).to eq(8)
          expect(small).to eq('ccb19ba6')
        end

        it 'Converts large description to 8 character hash' do 
          big = collector.format_desc('test more strings with spaces_and_underscores')
          expect(big).to eq('a6bb61fe')
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
          expect(str).to eq '101_de72bdae_small_unique_name'
        end

        it 'Creates a readable stamp from a single word' do
          str = collector.build_stamp('API', 101)
          expect(str).to eq '101_0fbef1b4_API'
        end

        it 'Creates a readable stamp from a three word sentence' do
          str = collector.build_stamp('There be dragons', 101)
          expect(str).to eq '101_0de17114_There_be_dragons'
        end

        it 'Prefixes git commit hash with commit date' do
          result = collector.results.first.description.match(/\d{8}T\d{6}/)
          expect(result).not_to eq nil
        end
      end
    end
  end
end