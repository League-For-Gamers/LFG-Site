class Tag < ActiveRecord::Base
  validates :name, presence: true
  validates :name, length: {maximum: 50}
  # TODO: Work out the specifics of tags. Will they allow spaces, for example?
end
