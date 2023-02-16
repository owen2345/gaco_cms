# frozen_string_literal: true

module GacoCms
  class Engine < ::Rails::Engine
    # isolate_namespace GacoCms # when enabled routes are not sharable

    engine_dir = File.expand_path('../../', __dir__)
    initializer 'gaco_cms.assets.precompile' do |app|
      builds_path = File.join(engine_dir, 'app/assets/builds/')
      if app.config.try(:assets)
        app.config.assets.precompile += [
          File.join(builds_path, 'gaco_cms.js'),
          File.join(builds_path, 'gaco_cms.css'),
          File.join(builds_path, 'gaco_cms_front.js'),
          File.join(builds_path, 'gaco_cms_front.css')
        ]
      end

      static_assets = File.join(engine_dir, 'vendor/static')
      target_path = Rails.root.join('public/assets/gaco_cms')
      unless Dir.exist?(target_path)
        Rails.logger.info '********gaco_cms: copying static assets....'
        FileUtils.mkpath(target_path) unless Dir.exist?(target_path)
        FileUtils.cp_r(File.join(static_assets, '.'), target_path)

        # puts '*********gaco_cms: copying compiled gaco_cms assets for importmaps'
        FileUtils.cp_r(File.join(builds_path, '.'), app.root.join('public/assets/'))
      end
    end
  end
end
