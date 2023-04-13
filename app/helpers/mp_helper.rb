# 微信公众号助手函数
module MpHelper
  # 微信公众号二维码
  def mp_qrcode_base64
    path = ENV["MP_QRCODE_ABS_PATH"]
    return '' unless path.present? && File.exist?(path)
    data = File.open(path).read
    encode = Base64.encode64(data)
    "data:#{MIME::Types.type_for(path).first.content_type};base64,#{encode.gsub(/\n/, '')}"
  end
end
