require 'reddit/watch/tagged_data'

module Lemtzas
  module Reddit
    module Watch
      # Safe execution helpers for Redd
      class Base
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
    end # module Watch
  end # module Reddit
end # module Lemtzas
