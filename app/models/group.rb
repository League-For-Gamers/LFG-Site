class Group < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search_by_title, against: :title

  # Public and private cannot be used for method names as they as reserved
  enum privacy: [:public_group, :private_group]
  enum post_control: [:public_posts, :management_only_post, :members_only_post]
  enum comment_privacy: [:public_comments, :members_only_comment, :private_comments]
  enum membership: [:public_membership, :owner_verified, :invite_only]

  has_attached_file :banner,
                  default_url: "/group/banner/:style/missing.png",
                  path: "/group/banner/:style/:id.:extension",
                  styles: {
                    thumb: '356x200#',
                    large: '1500x400#'
                  }

  default_scope { order("membership_count DESC, title ASC") }


  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  has_many :posts, -> { order 'created_at DESC' }, dependent: :destroy

  validates :title, :slug, presence: true, uniqueness: {case_sensitive: false}, length: { maximum: 38 }
  validates :description, allow_blank: true, allow_nil: true, length: { maximum: 1000 }
  validates_attachment :banner, content_type: { content_type: ['image/jpeg', 'image/png', 'image/bmp'] },
                       attachment_size: { less_than: 2048.kilobytes }
  validates :privacy, :membership, presence: true
  validate :validates_reserved_names

  before_validation do
    self.slug = title.parameterize('_') unless title.blank?
  end

  private
    def validates_reserved_names
      errors.add(:group, "cannot use a reserved name") if self.title.present? and ["new", "search", "admin", "administrator", "administrators"].include? self.title.downcase
    end
end
