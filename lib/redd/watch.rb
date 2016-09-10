require_relative 'redd_safe.rb'
require_relative 'models.rb'

module Lemtzas
  module Reddit
    module Processing
      # Represents tagged data for processing with a ReddWatchBase
      class TaggedData
        attr_accessor :tag, :data
        def initialize(tag, data)
          @tag = tag
          @data = data
        end

        def to_s
          data.to_s
        end
      end

      # Safe execution helpers for Redd
      class WatchBase
        SEEN_TRACK_LIMIT_DEFAULT = 200

        # Initialize a WatchBase
        # @param seen_track_limit [Number] The number of tags to track.
        def initialize(seen_track_limit = SEEN_TRACK_LIMIT_DEFAULT)
          @seen_queue = Queue.new
          @seen_set = Set.new
          @seen_track_limit = seen_track_limit

          # throw away the first scan worth of data
          unseen
        end

        # Retrieve any unseen messages
        # Override in subclass to extend behavior
        def unseen
          latest_data = retrieve
          unless latest_data.all? { |td| td.is_a? TaggedData }
            raise 'retrieve returned non-TaggedData object'
          end
          unseen_data = latest_data.select { |td| !saw?(td.tag) }
          unseen_data.each { |td| see td.tag }
          unseen_data.map(&:data)
        end

        alias latest unseen

        protected

        # Retrieve the latest messages in the form of TaggedData
        # Override in subclass to extend behavior
        def retrieve
          raise 'Retrieve latest not overridden, or calling base class.'
        end

        # Mark the tag as seen.
        def see(tag)
          add_to_seen tag
          cull_seen
        end

        # Has the tag been seen?
        def saw?(tag)
          @seen_set.include? tag
        end

        private

        # Add the tag to the seen tags
        def add_to_seen(tag)
          @seen_queue.enq tag
          @seen_set.add tag
        end

        # Cull excess seen tags
        def cull_seen
          if @seen_queue.length > @seen_track_limit
            old_tag = @seen_queue.deq
            @seen_set.delete old_tag
            old_tag
          end
          nil
        end
      end # class WatchBase

      # Get the latest modmail messages
      class ModmailWatch < WatchBase
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
            TaggedData.new(m.name, Models::Modmail.from_data(m))
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

      # Get the latest subreddit submissions
      class SubmissionWatch < WatchBase
        RETRIEVAL_COUNT = 10

        def initialize(redd_safe, subreddit)
          unless redd_safe.is_a? ReddSafe
            raise "redd_safe of unexpected type #{redd_safe.class}"
          end
          @redd = redd_safe
          @subreddit = subreddit
          super()
        end

        # Retrieve the latest messages in the form of TaggedData
        # Override in subclass to extend behavior
        def retrieve
          messages =
            @redd.subreddit_from_name(@subreddit)
                 .get_new(limit: RETRIEVAL_COUNT)
          messages.map do |m|
            TaggedData.new(m.name, Models::Submission.from_data(m))
          end
        end
      end # module SubmissionWatch

      # Get the latest subreddit comments
      class CommentWatch < WatchBase
        RETRIEVAL_COUNT = 10

        def initialize(redd_safe, subreddit)
          unless redd_safe.is_a? ReddSafe
            raise "redd_safe of unexpected type #{redd_safe.class}"
          end
          @redd = redd_safe
          @subreddit = subreddit
          super()
        end

        # Retrieve the latest messages in the form of TaggedData
        # Override in subclass to extend behavior
        def retrieve
          messages =
            @redd.subreddit_from_name(@subreddit)
                 .get_comments(limit: RETRIEVAL_COUNT)
          messages.map do |m|
            TaggedData.new(m.name, Models::Comment.from_data(m))
          end
        end
      end # module SubmissionWatch
    end # module Processing
  end # module Redd
end # module Lemtzas
