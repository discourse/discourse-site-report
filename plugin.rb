# name: discourse-site-report
# version: 0.1

enabled_site_setting :site_report_enabled

PLUGIN_NAME = 'site-report'.freeze

add_admin_route 'site-report.title', 'site-report'

after_initialize do

  require_dependency 'admin_constraint'

  module ::SiteReport
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace SiteReport
    end
  end


  require_dependency 'application_controller'
  class SiteReport::SiteReportController < ::ApplicationController
    def index
    end

  end

  SiteReport::Engine.routes.draw do
    root to: 'site_report#index', constraints: AdminConstraint.new
  end

  Discourse::Application.routes.append do
    mount ::SiteReport::Engine, at: '/admin/plugins/site-report', constraints: AdminConstraint.new
  end
end
