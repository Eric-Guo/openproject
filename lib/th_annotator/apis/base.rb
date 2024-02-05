module ThAnnotator::Apis
  class Base
    @@access_token = nil
    @@access_token_expires_at = nil

    class << self
      def access_token
        if @@access_token.nil? || Time.now.to_i > @@access_token_expires_at
          new_token = get_access_token
          @@access_token = new_token[:token]
          @@access_token_expires_at = Time.now.to_i + new_token[:expires_in] - 300
        end

        @@access_token
      end

      # 获取系统TOKEN
      # @return [Hash{:token=>String,:expires_in=>Number}]
      def get_access_token
        params = {
          appID: ThAnnotator::Config.app_id,
          secret: ThAnnotator::Config.app_secret
        }

        result = ThAnnotator::Request.new.get('auth/getToken', params:)

        {
          token: result[:data][:accessToken],
          expires_in: result[:data][:expiresIn]
        }
      end

      # 获取用户TOKEN
      # @param email: [String] 邮箱
      # @return [String] 用户TOKEN
      def get_user_token(email:)
        params = {
          access_token:,
          email:
        }

        result = ThAnnotator::Request.new.get('auth', params:)

        result[:data][:token]
      end

      # 创建批注文档
      # @param file_name: [String] 文档名称
      # @param document_type: [String] 文档类型，固定值 - dds
      # @param app_id: [String] 应用ID
      # @param view_path: [String] 预览地址
      # @return [String] 文档UUID
      def create_document(file_name:, document_type:, view_path:)
        params = {
          access_token:
        }

        data = {
          fileName: file_name,
          documentType: document_type,
          appID: ThAnnotator::Config.app_id,
          viewPath: view_path
        }

        result = ThAnnotator::Request.new.post('documents', params:, data:)

        result[:data][:uuid]
      end

      # 同步文档参与人
      # @param uuid: [String] 文档ID
      # @param users: [Array{Hash{:name=>String,:email=>String,:is_internal=>String}}] 参与人
      # @return [String] 文档UUID
      def sync_document_users(uuid:, users:)
        params = {
          access_token:
        }

        data = {
          participants: users.map do |user|
            {
              name: user[:name],
              email: user[:email],
              isInternal: user[:is_internal]
            }
          end
        }

        result = ThAnnotator::Request.new.post("documents/#{uuid}/users", params:, data:)

        result[:data][:uuid]
      end
    end
  end
end
