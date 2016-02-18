class Ad < ApplicationRecord
  include BaseModel

  mount_uploader :cover, PhotoUploader

  validates :topic_id, presence: true, uniqueness: true
  ACCESSABLE_ATTRS = [:topic_id, :topic_title, :topic_author, :cover]
end