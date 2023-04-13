# 微信公众号助手函数
module MpHelper
  # 获取微信公众号二维码路径
  # size: large、middle、small
  def mp_qrcode_path(size = 'middle')
    ENV["MP_QRCODE_#{size.upcase}_PATH"] || ENV["MP_QRCODE_PATH"]
  end

  # 获取微信公众号二维码完整url
  # size: large、middle、small
  def mp_qrcode_url(size = 'middle')
    (ENV["MP_QRCODE_#{size.upcase}_URL"] || ENV["MP_QRCODE_URL"]) || (mp_qrcode_path && Pathname.new(root_url).join(mp_qrcode_path(size).delete_prefix('/')).to_s)
  end
end
