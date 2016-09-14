require 'redis'
require 'pry'
require 'bunny'
require 'securerandom'

require 'reddit/redd_safe'
require 'reddit/watch/modmail'
require 'common/messaging/reddit/modmail'
require 'reddit/watch/comments'
require 'common/messaging/reddit/comment'
require 'reddit/watch/submissions'
require 'common/messaging/reddit/submission'
require 'common/tracking'

module Lemtzas
  module Reddit
    module Monitor
      # The driver class
      class Driver
        include Common::Trackable
        attr_reader :id

        def initialize(subreddit_name: nil, scan_modmail: true)
          raise "No subreddit specified." unless subreddit_name
          redd_safe = Reddit::ReddSafe.new(
            ENV['reddit_client_id'], ENV['reddit_client_secret'],
            ENV['reddit_username'], ENV['reddit_password'])
          @subreddit_name = subreddit_name
          @modmail = Watch::Modmail.new(redd_safe) if scan_modmail
          @submissions = Watch::Submissions.new(redd_safe, @subreddit_name)
          @comments = Watch::Comments.new(redd_safe, @subreddit_name)

          @topic = init_bunny_topic
        end

        def run
          loop do
            # puts "[#{Time.now.utc}] Performing One Pass"
            modmail_pass
            submissions_pass
            comments_pass
            sleep(15)
          end
        rescue StandardError => e
          @topic.publish("#{e}\n\n#{e.backtrace}", routing_key: 'error')
          puts "[#{Time.now.utc}] Driver Loop Failure"
          puts $ERROR_INFO, $ERROR_POSITION
          raise
        end

        private

        def init_bunny_topic
          conn = Bunny.new(ENV['rabbitmq_url'])
          conn.start

          ch = conn.create_channel
          topic = ch.topic('reddit-monitor-live')

          ch.queue('live-modmail', durable: true)
            .bind(topic, routing_key: 'modmail.#')
          ch.queue('live-submissions', durable: true)
            .bind(topic, routing_key: 'submission.#')
          ch.queue('live-comments', durable: true)
            .bind(topic, routing_key: 'comment.#')
          ch.queue('errors', durable: true)
            .bind(topic, routing_key: 'error', source: 'reddit-monitor-live')

          ObjectSpace.define_finalizer(self, proc { conn.close })
          topic
        end

        def modmail_pass
          return unless @modmail
          modmails = @modmail.latest
          modmails.each do |modmail|
            message = Common::Messaging::Reddit::Modmail.from_data(modmail)
            message.track(self)
            @topic.publish(
              message.serialize,
              routing_key: "modmail.#{message.subreddit}")
            puts message
          end
        end

        def submissions_pass
          return unless @submissions
          submissions = @submissions.latest
          submissions.each do |submission|
            message = Common::Messaging::Reddit::Submission.from_data(submission)
            message.track(self)
            @topic.publish(
              message.serialize,
              routing_key: "submission.#{message.subreddit}")
            puts message
          end
        end

        def comments_pass
          return unless @comments
          comments = @comments.latest
          comments.each do |comment|
            message = Common::Messaging::Reddit::Comment.from_data(comment)
            message.track(self)
            actual_link_id = message.link_id.split('_')[1]
            @topic.publish(
              message.serialize,
              routing_key: "comment.#{message.subreddit}.#{actual_link_id}")
            puts message
          end
        end
      end # class Driver
    end # module Monitor
  end # module Reddit
end # module Lemtzas
