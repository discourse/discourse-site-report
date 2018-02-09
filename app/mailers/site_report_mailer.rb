require_dependency 'report'

class SiteReportMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers

  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email
  def report
    subject =  'this is a test'
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    visits_report = Report.find(:visits, start_date: start_date, end_date: end_date)

    puts "REPORTDATACURRENT #{visits_report.total}"
    puts "REPORTDATAPREV #{visits_report.prev30Days}"

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end
end
