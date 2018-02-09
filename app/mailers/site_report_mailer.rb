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
    mobile_visits_report = Report.find(:mobile_visits, start_date: start_date, end_date: end_date)
    signups_report = Report.find(:signups, start_date: start_date, end_date: end_date)
    profile_views_report = Report.find(:profile_views, start_date: start_date, end_date: end_date)
    topics_report = Report.find(:topics, start_date: start_date, end_date: end_date)
    posts_report = Report.find(:posts, start_date: start_date, end_date: end_date)
    time_to_first_response_report = Report.find(:time_to_first_response, start_date: start_date, end_date: end_date)
    topics_with_no_response_report = Report.find(:topics_with_no_response, start_date: start_date, end_date: end_date)
    emails_report = Report.find(:emails, start_date: start_date, end_date: end_date)
    flags_report = Report.find(:flags, start_date: start_date, end_date: end_date)
    likes_report = Report.find(:likes, start_date: start_date, end_date: end_date)
    solved_report = Report.find(:post_action, post_action_type: 15, start_date: start_date, end_date: end_date)


    puts "REPORTDATACURRENT #{visits_report.total}"
    puts "REPORTDATAPREV #{visits_report.prev30Days}"

    @data = {
      visits: visits_report.total,
      visits_prev: visits_report.prev30Days,
      mobile_visits: mobile_visits_report.total,
      mobile_visits_prev: mobile_visits_report.prev30Days,
      signups: signups_report.total,
      signups_prev: signups_report.prev30Days,
      profile_views: profile_views_report.total,

      topics: topics_report.total,
      posts: posts_report.total,
      response_time: time_to_first_response_report.total,
      no_response: topics_with_no_response_report.total,
      emails: emails_report.total,
      flags: flags_report.total,
      likes: likes_report.total,
      # solved: solved_report.total
    }


    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end
end
