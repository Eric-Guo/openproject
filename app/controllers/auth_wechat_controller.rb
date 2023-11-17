class AuthWechatController < ApplicationController
  skip_before_action :wechat_auto_login

  def index
    redirect_uri = params[:redirect_uri].presence || root_path
    token = params[:token]

    secret = ENV['WECHAT_AUTH_JWT_SECERT']

    begin
      payload, header = JWT.decode token, secret, true, { required_claims: ['exp'], algorithm: 'HS256' }
    rescue JWT::ExpiredSignature
      return render json: { message: '签名已过期' }, status: 500
    rescue JWT::DecodeError
      return render json: { message: 'Token解析错误' }, status: 500
    rescue Exception
      return render json: { message: '未知错误' }, status: 500
    end

    # 获取用户
    user_id = payload['sub']

    user = User.find(user_id)

    unless user.active?
      user.activate
      user.save!
    end

    # generate a key and set cookie if autologin
    if Setting::Autologin.enabled? && (params[:autologin] || session.delete(:autologin_requested))
      set_autologin_cookie(user)
    end

    # Set the logged user, resetting their session
    self.logged_user = user

    call_hook(:controller_account_success_authentication_after, user:)

    redirect_to redirect_uri
  end
end
