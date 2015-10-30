# coding: utf-8
class Ad
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::BaseModel

  field :topic_id
  field :topic_title
  field :topic_author
  mount_uploader :cover, PhotoUploader

  validates_uniqueness_of :topic_id
  validates_presence_of :cover, :topic_id

  ACCESSABLE_ATTRS = [:topic_id, :topic_title, :topic_author, :cover]
end
