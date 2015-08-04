# coding: utf-8
class QrcodeUploader < BaseUploader
  version :normal do
    process resize_to_fill: [48, 48]
  end

  version :small do
    process resize_to_fill: [16, 16]
  end

  version :large do
    process resize_to_fill: [230, 230]
  end

  version :big do
    process resize_to_fill: [300, 300]
  end

  def filename
    if super.present?
      "qrcode/#{model.id}.jpg"
    end
  end

  def extension_white_list
    %w(jpg jpeg png)
  end
end
