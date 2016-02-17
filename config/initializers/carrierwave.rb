
require 'carrierwave'
require 'carrierwave/validations/active_model'


class NullStorage
  attr_reader :uploader

  def initialize(uploader)
    @uploader = uploader
  end

  def identifier
    uploader.filename
  end

  def store!(_file)
    true
  end

  def retrieve!(_identifier)
    true
  end
end

CarrierWave.configure do |config|
  if Rails.env.test?
    # http://stackoverflow.com/questions/7534341/rails-3-test-fixtures-with-carrierwave/25315883#25315883
    config.storage NullStorage
  else
    config.storage = :file
  end
end
