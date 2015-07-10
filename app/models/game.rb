class Game < ActiveRecord::Base
  include Postable

  has_and_belongs_to_many :users
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :boxart, attachment_content_type: { content_type: /\Aimage\/.*\Z/ },
                     attachment_size: { less_than: 512.kilobytes }

  has_attached_file :boxart,
                    path: "games/boxart/:style/:id.:extension",
                    styles: {
                      small: '120x170^',
                      med:   '166x235>',
                      large: '360x510#'
                    }

  before_validation do
    remove_zalgo! self.name
  end
end
