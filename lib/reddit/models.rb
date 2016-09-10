require 'json'
require 'securerandom'

module Lemtzas
  module Reddit
    module Models
      # A mixin for tracking modules
      module Trackable
        attr_accessor :uuid,
                      :parent_uuid,
                      :script_uuid

        # Add tracking information
        def track(this: nil, parent: nil, script: nil)
          @uuid ||= this
          @parent_uuid ||= parent
          @script_uuid ||= script
          self
        end
      end # module Trackable

      # An object that can convert to/from json.
      # implement from_json on your own.
      # include JSONable
      # def self.from_json(string) new.from_json!(string) end
      module JSONable
        def to_json
          hash = {}
          instance_variables.each do |var|
            hash[var] = instance_variable_get var
          end
          hash.to_json
        end

        def from_json!(string)
          JSON.load(string).each do |var, val|
            instance_variable_set var, val
          end
          self
        end
      end # module JSONable

      # Represents a modmail message
      class Modmail
        include JSONable
        include Trackable
        def self.from_json(string) new.from_json!(string) end

        attr_accessor :body,
                      :name,
                      :id,
                      :author,
                      :created_utc,
                      :subreddit,
                      :subject,
                      :distinguished,
                      :first_message_name

        def shortlink
          "http://reddit.com/message/messages/#{id}"
        end

        def shorttext(length = 40, strip_newlines = true)
          text = body
          text = text.gsub(/\r|\n/, '') if strip_newlines
          text[0..length]
        end

        def to_s
          "Modmail /r/#{subreddit} /u/#{author} - #{shorttext} - #{shortlink}"
        end

        # Constructs a modmail from listing data
        def self.from_data(data)
          modmail = Modmail.new
          modmail.uuid = SecureRandom.uuid
          modmail.body = data.body
          modmail.name = data.name
          modmail.id = data.id
          modmail.author = data.author
          modmail.created_utc = data.created_utc
          modmail.subreddit = data.subreddit
          modmail.subject = data.subject
          modmail.distinguished = data.distinguished
          modmail.first_message_name = data.first_message_name
          modmail
        end
      end # class Modmail

      # Represents a submission
      class Submission
        include JSONable
        include Trackable
        def self.from_json(string) new.from_json!(string) end

        attr_accessor :name,
                      :id,
                      :author,
                      :title,
                      :selftext,
                      :subreddit,
                      :media,
                      :link_flair_text,
                      :link_flair_css_class,
                      :author_flair_text,
                      :author_flair_css_class,
                      :user_reports,
                      :report_reasons,
                      :mod_reports,
                      :gilded,
                      :banned_by,
                      :approved_by,
                      :score,
                      :nsfw,
                      :removal_reason,
                      :stickied,
                      :is_self,
                      :from,
                      :from_id,
                      :url,
                      :permalink,
                      :author_flair_text,
                      :created_utc,
                      :distinguished,
                      :num_reports

        def shortlink
          "http://redd.it/#{id}"
        end

        def shorttext(length = 40, strip_newlines = true)
          text = body
          text = text.gsub(/\r|\n/, '') if strip_newlines
          text[0..length]
        end

        def to_s
          "Submission /r/#{subreddit} /u/#{author} - [#{link_flair_text}] #{title} - #{shortlink}"
        end

        # Constructs a submission from listing data
        # rubocop:disable MethodLength
        # rubocop:disable AbcSize
        def self.from_data(data)
          submission = Submission.new
          submission.uuid = SecureRandom.uuid
          submission.name = data.name
          submission.id = data.id
          submission.author = data.author
          submission.title = data.title
          submission.selftext = data.selftext
          submission.subreddit = data.subreddit
          submission.media = data.media
          submission.link_flair_text = data.link_flair_text
          submission.link_flair_css_class = data.link_flair_css_class
          submission.author_flair_text = data.author_flair_text
          submission.author_flair_css_class = data.author_flair_css_class
          submission.user_reports = data.user_reports
          submission.report_reasons = data.report_reasons
          submission.mod_reports = data.mod_reports
          submission.gilded = data.gilded
          submission.banned_by = data.banned_by
          submission.approved_by = data.approved_by
          submission.score = data.score
          submission.nsfw = data.over_18
          submission.removal_reason = data.removal_reason
          submission.stickied = data.stickied
          submission.is_self = data.is_self
          submission.from = data.from
          submission.from_id = data.from_id
          submission.url = data.url
          submission.permalink = data.permalink
          submission.author_flair_text = data.author_flair_text
          submission.created_utc = data.created_utc
          submission.distinguished = data.distinguished
          submission.num_reports = data.num_reports
          submission
        rescue
          binding.pry
        end
      end # class Submission

      # Represents a modmail message
      class Comment
        include JSONable
        include Trackable
        def self.from_json(string) new.from_json!(string) end

        attr_accessor :link_title,        # string
                      :banned_by,         # username
                      :removal_reason,    # string
                      :link_id,           # t3_4zlvhc
                      :link_author,       # username
                      :replies,           # string?
                      :user_reports,      # array
                      :id,                # d6x7mfq
                      :gilded,            # number
                      :archived,          # bool
                      :stickied,          # bool
                      :author,            # username
                      :parent_id,         # t3_4zlvhc
                      :score,             # number
                      :approved_by,       # username
                      :nsfw,              # bool
                      :report_reasons,    # array
                      :controversiality,  # number
                      :body,              # markdown
                      :edited,            # bool (maybe UTC later?)
                      :author_flair_css_class,    # string
                      :author_flair_text,         # string
                      :quarantine,        # bool
                      :subreddit,         # string
                      :score_hidden,      # bool
                      :name,              # t1_d6x7mju
                      :created_utc,       # decimal number
                      :mod_reports,       # array
                      :num_reports,       # number
                      :distinguished,     # nil
                      :kind               # t1

        def shortlink
          actual_link_id = link_id.split('_')[0]
          "http://reddit.com/r/#{subreddit}/#{actual_link_id}../#{id}"
        end

        def shorttext(length = 40, strip_newlines = true)
          text = body
          text = text.gsub(/\r|\n/, '') if strip_newlines
          text[0..length]
        end

        def to_s
          "Comment /r/#{subreddit} /u/#{author} - #{link_title} - #{shorttext} - #{shortlink}"
        end

        # Constructs a modmail from listing data
        def self.from_data(data)
          comment = Comment.new
          comment.uuid = SecureRandom.uuid
          comment.link_title = data.link_title
          comment.banned_by = data.banned_by
          comment.removal_reason = data.removal_reason
          comment.link_id = data.link_id
          comment.link_author = data.link_author
          comment.replies = data.replies
          comment.user_reports = data.user_reports
          comment.id = data.id
          comment.gilded = data.gilded
          comment.archived = data.archived
          comment.stickied = data.stickied
          comment.author = data.author
          comment.parent_id = data.parent_id
          comment.score = data.score
          comment.approved_by = data.approved_by
          comment.nsfw = data.over_18
          comment.report_reasons = data.report_reasons
          comment.controversiality = data.controversiality
          comment.body = data.body
          comment.edited = data.edited
          comment.author_flair_css_class = data.author_flair_css_class
          comment.author_flair_text = data.author_flair_text
          comment.quarantine = data.quarantine
          comment.subreddit = data.subreddit
          comment.score_hidden = data.score_hidden
          comment.name = data.name
          comment.created_utc = data.created_utc
          comment.mod_reports = data.mod_reports
          comment.num_reports = data.num_reports
          comment.distinguished = data.distinguished
          comment.kind = data.kind
          comment
        rescue
          binding.pry
        end
      end # class Comment
    end # module Models
  end # module Reddit
end # module Lemtzas
