# encoding: UTF-8
module MongoMapper
  module Extensions
    module Fixnum
      BASE62_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      # based on http://flowcoder.com/148
      # The encode is skipping the first 'a' when will change the digits size 62, 62 * 62
      # FIXME 1.to_base62.should eql 'a' NOT 'b'
      # FIXME 62.to_base62.should eql '99' NOT 'ba'
      # FIXME 3844.to_base62.should eql '99' NOT 'baa'
      # FIXME 238328.to_base62.should eql '999' NOT 'baaa'
      # @pablocantero
      def to_base62
        i = self
        return '0' if i == 0
        s = ''
        while i > 0
          s << BASE62_CHARS[i.modulo(62)]
          i /= 62
        end
        s.reverse!
        s
      end
    end
  end
end

class Fixnum
  include MongoMapper::Extensions::Fixnum
end