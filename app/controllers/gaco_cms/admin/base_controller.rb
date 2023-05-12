# frozen_string_literal: true

module GacoCms
  module Admin
    class BaseController < GacoCms::AdminController
      skip_before_action :verify_authenticity_token, only: :upload_file

      def upload_file
        file = GacoCms::MediaFile.new(file: params[:file])
        if file.save
          render json: { location: file.url }
        else
          render json: { error: file.errors.full_message.join(', ') }
        end
      end

      def index; end
    end
  end
end
