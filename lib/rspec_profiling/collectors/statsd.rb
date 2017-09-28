require "statsd";

module RspecProfiling
  module Collectors
    class Statsd
      #delegate :timing, :increment, :count, :gauge, :time, :batch, to: :statsd, allow_nil: true 
      NAMESPACE = "rspec_profiling"
      #Property used by CSV Collector, leaving it here
      #to maintain reference of available properties.
      HEADERS = %w{
        branch
        commit_hash
        date
        file
        line_number
        description
        status
        exception
        time
        query_count
        query_time
        request_count
        request_time
      }

      attr_accessor :statsd 
      
      def self.install
        # no op
      end

      def self.uninstall
        # no op
      end

      def self.reset
        # no op
      end

      def initialize
        RspecProfiling.config.statsd_host ||= '127.0.0.1';
        RspecProfiling.config.statsd_port ||= '8125';
        
        self.statsd = ::Statsd.new(RspecProfiling.config.statsd_host, RspecProfiling.config.statsd_port).tap do |sd|
          sd.namespace = "ldxe.#{NAMESPACE}.app"
        end

      end

      def insert(attributes)
        hash = attributes.fetch(:commit_hash)
        testDesc = attributes.fetch(:description)
        key = "#{hash}.#{testDesc}"

        self.statsd.batch do |b|
            b.timing("#{key}.process_time", attributes.fetch(:time))
            b.count("#{key}.request_count", attributes.fetch(:request_count))
            b.timing("#{key}.request_time", attributes.fetch(:request_time))
        end
      end
    end
  end
end
