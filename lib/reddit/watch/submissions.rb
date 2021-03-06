require 'reddit/watch/base'
require 'reddit/watch/tagged_data'
require 'reddit/redd_safe'

module Lemtzas
  module Reddit
    module Watch
      # Get the latest subreddit submissions
      class Submissions < Watch::Base
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
            @redd.get_new(@subreddit, limit: RETRIEVAL_COUNT)
          messages.map do |m|
            TaggedData.new(m.name, m)
          end
        end
      end # module SubmissionWatch
    end # module Watch
  end # module Reddit
end # module Lemtzas
