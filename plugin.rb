# name: discourse-site-report
# version: 0.1

enabled_site_setting :site_report_enabled

PLUGIN_NAME = 'site-report'.freeze

add_admin_route 'site_report.title', 'site-report'

after_initialize do

  require_dependency 'admin_constraint'

  module ::SiteReport
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace SiteReport
    end
  end

  [
    '../../discourse-site-report/app/mailers/site_report_mailer.rb',
    '../../discourse-site-report/app/jobs/site_report.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  require_dependency 'application_controller'
  class SiteReport::SiteReportController < ::ApplicationController
    def index
    end

    def preview
      # puts "THIS IS A TEST FROM THE PREVIEW FUNCTION #{current_user.email}"
      # email = current_user.email
      SiteReport::SiteReportMailer.report.deliver_now

      render json: { success: true }
    end
  end

  SiteReport::Engine.routes.draw do
    root to: 'site_report#index', constraints: AdminConstraint.new
    get 'preview', to: 'site_report#preview', constraints: AdminConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::SiteReport::Engine, at: '/admin/plugins/site-report', constraints: AdminConstraint.new
  end

end
