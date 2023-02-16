# frozen_string_literal: true

require 'rails/generators/base'
module GacoCms
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../install_template', __FILE__)
      desc 'This generator copies all basic settings for GacoCMS'

      def create_initializer_file
        copy_file 'gaco_cms.rb', 'config/initializers/gaco_cms.rb'
        directory('themes', 'app/views/themes')
      end
    end
  end
end
