require 'statsd';
require 'logger';
require 'digest';


module RspecProfiling
  module Collectors
    class Statsd
      #delegate :timing, :increment, :count, :gauge, :time, :batch, to: :statsd, allow_nil: true 
      NAMESPACE = 'rspec_profiling'

      DATE_FORMAT_INPUT = '%a %b %d %H:%M:%S %Y'
      DATE_FORMAT_OUTPUT = '%Y%m%dT%H%M%S'
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

      def health(host, port, protocol)
        flags = host =~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ ? '-vzn' : '-vz'
        case protocol
          when :udp
            flags << 'u'
        end
        result = `nc #{flags} #{host} #{port} 2>&1 > /dev/null`
        result =~ /open|succe(ss|eded)/
      end

      def health_check
        if self.health(RspecProfiling.config.statsd_host, RspecProfiling.config.statsd_port, RspecProfiling.config.statsd_protocol) 
          @logger.info("rspec_profiling connection test to statsd socket at [#{RspecProfiling.config.statsd_host}:#{RspecProfiling.config.statsd_port}] is successful.")
        else
          @logger.warn("rspec_profiling cannot connect to statsd socket at [#{RspecProfiling.config.statsd_host}:#{RspecProfiling.config.statsd_port}]. You will not see profiling results.")
        end
      end

      def self.reset
        @results = Array.new
      end

      def install
        self.statsd.increment('profiling_live')
      end

      def uninstall
        self.statsd.decrement('profiling_live')
      end

      def initialize
        RspecProfiling.config.statsd_host ||= '127.0.0.1'
        RspecProfiling.config.statsd_port ||= '8125'
        RspecProfiling.config.statsd_max_depth ||= 0
        RspecProfiling.config.statsd_protocol ||= :udp
        @results = Array.new
        @resultType = Struct.new(:description, :process_time)
        @statsd = nil
        @logger = Logger.new(STDOUT)
      end

      def statsd
        return @statsd unless @statsd.nil?
        self.health_check
        @statsd = ::Statsd.new(RspecProfiling.config.statsd_host, RspecProfiling.config.statsd_port, RspecProfiling.config.statsd_protocol).tap do |sd|
          sd.namespace = "ldxe.#{NAMESPACE}.app"
        end
      end
      
      def format_desc(description)
        ::Digest::SHA1.hexdigest(description)[8..15]
      end

      def format_file(path, max = 0) 
        str = path.gsub('/', '.').gsub(/\.rb$|^\.[^.]*\./, '')
        if max > 0
          parts = str.split('.')
          str = (parts[0..max-1] << parts[-1]).join('.')
        end
        return str
      end

      def format_date(date)
        date.strftime(DATE_FORMAT_OUTPUT)
      end

      def build_stamp(desc, line_number)
        hash_desc = format_desc(desc)
        readable_short = format_readable_short(desc)
        "#{line_number}_#{hash_desc}_#{readable_short}"
      end

      def format_readable_short(description) 
        result = description.split(' ')
        if result.length > 3
          #Look for larger words to avoid prepositions and articles.
          selected = result.select { |short| short.length > 3 }
          #If this results in less than 3 words then use the original array.
          selected = selected.length >= 3 ? selected : result
          #Shorten to the last 3
          result = shorten_array(selected, 3)
        end
        return result.join('_')
      end

      def shorten_array(arr, max)
        max = arr.length if arr.length < max
        arr[-max..-1] 
      end

      def format_readable_short(description) 
        result = description.split(' ')
        if result.length > 3
          #Look for larger words to avoid prepositions and articles.
          selected = result.select { |short| short.length > 3 }
          #If this results in less than 3 words then use the original array.
          selected = selected.length >= 3 ? selected : result
          #Shorten to the last 3
          result = shorten_array(selected, 3)
        end
        return result.join('_')
      end

      def shorten_array(arr, max)
        max = arr.length if arr.length < max
        arr[-max..-1] 
      end

      def insert(attributes)
        hash = attributes.fetch(:commit_hash)[0..7]
        stamp = build_stamp(attributes.fetch(:description), attributes.fetch(:line_number))
        path = format_file(attributes.fetch(:file))
        branch = attributes.fetch(:branch)
        commit_date = format_date(attributes.fetch(:date))
        key = "#{branch}.#{commit_date}_#{hash}.#{path}.#{stamp}".gsub("\n", '')

        self.statsd.batch do |b|
          b.timing("#{key}.process_time", attributes.fetch(:time))
          b.timing("#{key}.request_time", attributes.fetch(:request_time))
          b.count("#{key}.request_count", attributes.fetch(:request_count))
          result = @resultType.new(key, attributes.fetch(:time))
          @results.push(result)
        end
      end
    end
  end
end
