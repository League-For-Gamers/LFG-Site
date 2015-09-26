class PhotoMetadatum < ActiveRecord::Base
    validates_attachment :photo, content_type: { content_type: ['image/jpeg', 'image/png', 'image/bmp'] },
                       attachment_size: { less_than: 2.megabytes }
end
