# encoding: UTF-8
module MongoMapper
  module Extensions
    module Time
      def to_mongo(value)
        if !value.present?
          nil
        else
          time_class = ::Time.try(:zone) || ::Time
          time = value.is_a?(::Time) ? value : time_class.parse(value.to_s)
          at(time.to_f).utc if time # ensure milliseconds are preserved with to_f (issue #308)
        end
      end

      def from_mongo(value)
        if value and zone = ::Time.try(:zone)
          value.in_time_zone(zone)
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