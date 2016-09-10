module Lemtzas
  module Reddit
    module Watch
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
    end # module Watch
  end # module Reddit
end # module Lemtzas
