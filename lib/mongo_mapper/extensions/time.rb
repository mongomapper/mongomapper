# encoding: UTF-8
module MongoMapper
  module Extensions
    module Time
      def to_mongo(value)
        if value.nil? || value == ''
          nil
        else
          time_class = ::Time.try(:zone).present? ? ::Time.zone : ::Time
          time = value.is_a?(::Time) ? value : time_class.parse(value.to_s)
          # for ree (1.8.7) versions
          if RUBY_VERSION < "1.9"
            at(Float((time.to_f*1000).to_i)/Float(1000)).utc if time # ensure milliseconds are preserved with to_f (issue #308)            
          else
            at(time.to_f).utc.round(3) if time # ensure milliseconds are preserved with to_f (issue #308)            
          end
        end
      end

      def from_mongo(value)
        if ::Time.try(:zone).present? && value.present?
          value.in_time_zone(::Time.zone)
        else
          value
        end
      end

    end
  end
end

class Time
  extend MongoMapper::Extensions::Time
end