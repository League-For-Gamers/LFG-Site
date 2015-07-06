module Postable
	extend ActiveSupport::Concern

  # Remove Zalgo from display names.
  # It's not perfect, but it should do just fine, it's threshold based 
  # So it shouldn't catch smaller fancy-text things.
	def remove_zalgo!(text)
    text.gsub!(/[\u0300-\u036f\u0489]/, '') if text =~ /[\u0300-\u036f\u0489]{3}/
  end
end