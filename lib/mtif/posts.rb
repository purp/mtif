require "time"

class MTIF
  class Post
    attr_accessor :source, :data

    SINGLE_VALUE_KEYS = %w(author title status basename date unique_url body extended_body excerpt
    keywords allow_comments allow_pings convert_breaks no_entry primary_category).map(&:to_sym)
    MULTILINE_KEYS = %w(body extended_body excerpt keywords comment ping).map(&:to_sym)
    MULTIVALUE_KEYS = %w(category tags comment ping).map(&:to_sym)

    CSV_KEYS = %w(tags).map(&:to_sym)

    VALID_KEYS = (SINGLE_VALUE_KEYS + MULTILINE_KEYS + MULTIVALUE_KEYS).sort.uniq

    DATE_FORMAT = "%m/%d/%Y %I:%M:%S %p"
    
    FIELD_SEPARATOR = '-----'
    POST_SEPARATOR = '--------'

    def valid_keys
      VALID_KEYS
    end

    def valid_key?(key)
      valid_keys.include?(key.to_sym)
    end

    def single_line_single_value_keys
      SINGLE_VALUE_KEYS - MULTILINE_KEYS
    end

    def single_line_multivalue_keys
      MULTIVALUE_KEYS - MULTILINE_KEYS
    end

    def multiline_single_value_keys
      MULTILINE_KEYS & SINGLE_VALUE_KEYS
    end

    def multiline_multivalue_keys
      MULTILINE_KEYS & MULTIVALUE_KEYS
    end

    def initialize(content)
      @source = content
      @data = {}

      MULTIVALUE_KEYS.each do |key|
        @data[key] = []
      end

      parse_source
    end

    def to_mtif
      result = []
      single_line_single_value_keys.each do |key|
        value = self.send(key)
        next if value.nil? || (value.respond_to?(:empty) && value.empty?)

        result << "#{mtif_key(key)}: #{mtif_value(value)}"
      end

      single_line_multivalue_keys.each do |key|
        values = self.send(key)
        next if values.nil? || (values.respond_to?(:empty) && values.empty?)

        if CSV_KEYS.include?(key)
          values = [
            values.map{|v|
              v.include?("\s") ? "\"#{v}\"" : v
            }.join(',')
          ]
        end

        values.each do |value|
          result << "#{mtif_key(key)}: #{mtif_value(value)}"
        end
      end

      multiline_single_value_keys.each do |key|
        value = self.send(key)
        next if value.nil? || (value.respond_to?(:empty) && value.empty?)

        result << FIELD_SEPARATOR
        result << "#{mtif_key(key)}:\n#{mtif_value(value)}"
      end

      multiline_multivalue_keys.each do |key|
        values = self.send(key)
        next if values.nil? || (values.respond_to?(:empty) && values.empty?)

        values.each do |value|
          result << FIELD_SEPARATOR
          result << "#{mtif_key(key)}:\n#{mtif_value(value)}"
        end
      end


      result << FIELD_SEPARATOR unless result.last == FIELD_SEPARATOR #close the final field
      result << POST_SEPARATOR # close the post
      result.join("\n") + "\n"
    end

    private
    def method_missing(method, *args, &block)
      key = method.to_s.chomp('=').to_sym

      if valid_key?(key)
        if key == method
          data[key]
        else
          data[key] = args.first
        end
      else
        super
      end
    end

    def respond_to_missing?(method, include_all)
      key = method.to_s.chomp('=').to_sym

      valid_key?(key) || super
    end

    def mtif_key_to_key(raw_key)
      raw_key.strip.downcase.tr(' ','_').to_sym unless raw_key.nil?
    end

    def mtif_key(key)
      key.to_s.tr('_', ' ').upcase
    end

    def mtif_value(value)
      value.kind_of?(Time) ? value.strftime(DATE_FORMAT) : value
    end

    def convert_to_native_type(raw_value)
      case raw_value
      when /^\d+$/
        raw_value.to_i
      when /^\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2} [AP]M/
        Time.strptime(raw_value, DATE_FORMAT)
      else
        raw_value
      end
    end

    def store_data(raw_key, raw_value)
      key = mtif_key_to_key(raw_key)
      value = convert_to_native_type(raw_value)

      if MULTIVALUE_KEYS.include?(key)
        if CSV_KEYS.include?(key)
          value.split(',').each do |v|
            self.data[key] << v.gsub(/^\"|\"$/, '') unless v.empty?
          end
        else
          self.data[key] << value unless value.empty?
        end
      else
        self.data[key] = value
      end
    end

    def parse_source
      source.slice_before(/^#{FIELD_SEPARATOR}/).each do |lines|
        if lines.first =~ /^#{FIELD_SEPARATOR}/ && lines.size > 1
          # Multiline data
          store_data(lines.shift(2).last.chomp(":\n"), lines.join.strip)
        elsif lines.first =~ /^[A-Z ]+: /
          # Single-line data
          lines.each do |line|
            unless line.strip.empty?
              key, value = line.strip.split(": ", 2)
              store_data(key, value)
            end
          end
        end
      end
    end
  end
end
