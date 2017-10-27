require "statsd";
require "logger";
require "open3";



module RspecProfiling
  module Collectors
    class Statsd
      #delegate :timing, :increment, :count, :gauge, :time, :batch, to: :statsd, allow_nil: true 
      NAMESPACE = 'rspec_profiling'
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

      attr_accessor :statsd, :results, :logger
      
      def self.install
        new.install
      end

      def self.uninstall
        new.uninstall
      end

      def health(host, port)
        `nc -vuzn #{host} #{port} 2>&1 > /dev/null`.include? 'open'
      end

      def healthCheck
        if(self.health RspecProfiling.config.statsd_host, RspecProfiling.config.statsd_port) 
          @logger.info('Green light for statsd client')
        else
          @logger.warn('RED LIGHT for statsd client')
        end
      end

      def self.reset
        @results = Array.new;
      end

      def install
        self.statsd.increment 'profiling_live'
      end

      def uninstall
        self.statsd.decrement 'profiling_live'
      end


      def initialize
        RspecProfiling.config.statsd_host ||= '127.0.0.1';
        RspecProfiling.config.statsd_port ||= '8125';
        @results = Array.new;
        @resultType = Struct.new(:description, :process_time)
        @statsd = false
        @logger = Logger.new(STDOUT)
      end

      def statsd
        if(!@statsd)
          puts self.healthCheck
          @statsd = ::Statsd.new(RspecProfiling.config.statsd_host, RspecProfiling.config.statsd_port).tap do |sd|
            sd.namespace = "ldxe.#{NAMESPACE}.app"
          end
        end
        @statsd
      end

      def insert(attributes)
        hash = attributes.fetch(:commit_hash)[0..7]
        testDesc = attributes.fetch(:description)
        branch = attributes.fetch(:branch)
        key = "#{branch}.#{hash}.#{testDesc}".gsub("\n", "")

        self.statsd.batch do |b|
            b.timing("#{key}.process_time", attributes.fetch(:time))
            b.timing("#{key}.request_time", attributes.fetch(:request_time))
            b.count("#{key}.request_count", attributes.fetch(:request_count))
            result = @resultType.new(testDesc, attributes.fetch(:time))
            @results.push(result)
        end
      end
    end
  end
end
