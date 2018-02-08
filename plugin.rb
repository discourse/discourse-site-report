# name: discourse-site-report
# version: 0.1

enabled_site_setting :site_report_enabled

PLUGIN_NAME = 'site-report'.freeze

after_initialize do
 [
   '../app/mailers/site_report_mailer.rb',
   '../app/jobs/send_site_report.rb'
 ].each { |path| load File.expand_path(path, __FILE__) }

end
