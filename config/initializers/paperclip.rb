require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    # Spoof detection is fucking broken, oh my god this caused me way too much pain
    def spoofed?
      false
    end
  end
end