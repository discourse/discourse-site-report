class SiteReportMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers

  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email
  def report
    subject =  'this is a test'

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end
end
