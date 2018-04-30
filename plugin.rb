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

  require_dependency 'admin/admin_controller'
  class SiteReport::SiteReportController < ::Admin::AdminController
    def preview
      SiteReport::SiteReportMailer.report(send_to: current_user.email).deliver_now

      render json: { success: true }
    end
  end

  SiteReport::Engine.routes.draw do
    get 'preview', to: 'site_report#preview', constraints: AdminConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::SiteReport::Engine, at: '/admin/plugins/site-report', constraints: AdminConstraint.new
  end

end
