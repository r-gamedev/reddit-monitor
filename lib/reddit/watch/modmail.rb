require 'reddit/watch/base'
require 'reddit/watch/tagged_data'
require 'reddit/redd_safe'

module Lemtzas
  module Reddit
    module Watch
      # Get the latest modmail messages
      class Modmail < Watch::Base
        RETRIEVAL_COUNT = 10

        def initialize(redd_safe)
          unless redd_safe.is_a? ReddSafe
            raise "redd_safe of unexpected type #{redd_safe.class}"
          end
          @redd = redd_safe
          super()
        end

        # Retrieve the latest messages in the form of TaggedData
        # Override in subclass to extend behavior
        def retrieve
          messages = @redd.my_messages('moderator', false, limit: RETRIEVAL_COUNT)
          messages = expand(messages)
          messages.map do |m|
            TaggedData.new(m.name, m)
          end
        end

        private

        def expand(input)
          if input.is_a? Array
            expand_many(input)
          else
            expand_one(input)
          end
        end

        def expand_many(messages)
          messages.collect { |m| expand m }
                  .flatten
        end

        def expand_one(message)
          return message if message.replies.nil? || message.replies.empty?
          messages = [message]
          replies = ::Redd::Objects::Listing.new(@redd, message.replies[:data])
          replies.each { |r| messages << r }
          messages
        end
      end
    end # module Watch
  end # module Reddit
end # module Lemtzas
