class Tag < ActiveRecord::Base
  belongs_to :user
  # Stolen from twitters hashtag regexes.
  # https://github.com/twitter/twitter-text/blob/master/rb/lib/twitter-text/regex.rb#L107
  TAG_ALPHA = /[\p{L}\p{M}]/
  TAG_ALPHANUMERIC = /[\p{L}\p{M}\p{Nd}_\u200c\u200d\u0482\ua673\ua67e\u05be\u05f3\u05f4\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\u00b7]/

  validates :name, presence: true
  validates :name, length: {minimum: 3, maximum: 50}
  validates_uniqueness_of :name, scope: :user_id
  validates_format_of :name, with: /\A#{TAG_ALPHANUMERIC}*#{TAG_ALPHA}#{TAG_ALPHANUMERIC}*\z/io, message: "has invalid structure"
end
