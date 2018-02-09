require_dependency 'report'

class SiteReportMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers

  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email

  def report
    subject = 'this is a test'
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    previous_start_date = 2.months.ago.beginning_of_month
    previous_end_date = 2.months.ago.end_of_month

    visits = Report.find(:visits, start_date: start_date, end_date: end_date)
    mobile_visits = Report.find(:mobile_visits, start_date: start_date, end_date: end_date)
    signups = Report.find(:signups, start_date: start_date, end_date: end_date)
    profile_views = Report.find(:profile_views, start_date: start_date, end_date: end_date)
    topics = Report.find(:topics, start_date: start_date, end_date: end_date)
    posts = Report.find(:posts, start_date: start_date, end_date: end_date)
    time_to_first_response = Report.find(:time_to_first_response, start_date: start_date, end_date: end_date)
    topics_with_no_response = Report.find(:topics_with_no_response, start_date: start_date, end_date: end_date)
    emails = Report.find(:emails, start_date: start_date, end_date: end_date)
    flags = Report.find(:flags, start_date: start_date, end_date: end_date)
    likes = Report.find(:likes, start_date: start_date, end_date: end_date)
    accepted_solutions = Report.find(:accepted_solutions, start_date: start_date, end_date: end_date)

    discourse_reports = {
      visits: Report.find(:visits, start_date: start_date, end_date: end_date),
      mobile_visits: Report.find(:mobile_visits, start_date: start_date, end_date: end_date),
      signups: Report.find(:signups, start_date: start_date, end_date: end_date),
      profile_views: Report.find(:profile_views, start_date: start_date, end_date: end_date),
      topics: Report.find(:topics, start_date: start_date, end_date: end_date),
      posts: Report.find(:posts, start_date: start_date, end_date: end_date),
      time_to_first_response: Report.find(:time_to_first_response, start_date: start_date, end_date: end_date),
      topics_with_no_response: Report.find(:topics_with_no_response, start_date: start_date, end_date: end_date),
      emails: Report.find(:emails, start_date: start_date, end_date: end_date),
      flags: Report.find(:flags, start_date: start_date, end_date: end_date),
      likes: Report.find(:likes, start_date: start_date, end_date: end_date),
      accepted_solutions: Report.find(:accepted_solutions, start_date: start_date, end_date: end_date)
    }

    @data = {}

    discourse_reports.each do |key, discourse_report|
      @data[key] = create_data(key, discourse_report.total, discourse_report.prev30Days )
    end

    repeat_new_users = repeat_new_users start_date, end_date, 2
    previous_repeat_new_users = repeat_new_users previous_start_date, previous_end_date, 2

    # @data = {
    #   visits: visits_report ? { current: visits_report.total, prev: visits_report.prev30Days } : nil,
    #   mobile_visits: mobile_visits_report.total,
    #   mobile_visits_prev: mobile_visits_report.prev30Days,
    #   signups: signups_report.total,
    #   signups_prev: signups_report.prev30Days,
    #   profile_views: profile_views_report.total,
    #
    #   topics: topics_report.total,
    #   posts: posts_report.total,
    #   response_time: time_to_first_response_report.total,
    #   no_response: topics_with_no_response_report.total,
    #   emails: emails_report.total,
    #   flags: flags_report.total,
    #   likes: likes_report.total,
    #   solutions: accepted_solutions_report.total
    # }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}
    mail(to: admin_emails, subject: subject)
  end

  def repeat_new_users(period_start, period_end, num_visits)
    sql = <<~SQL
      WITH period_new_users AS (
      SELECT 
      u.id
      FROM users u
      WHERE u.created_at >= :period_start
      AND u.created_at <= :period_end
      ),
      period_visits AS (
      SELECT
      uv.user_id,
      COUNT(1) AS visit_count
      FROM user_visits uv
      WHERE uv.visited_at >= :period_start
      AND uv.visited_at <= :period_end
      GROUP BY uv.user_id
      )
      SELECT
      pnu.id
      FROM period_new_users pnu
      JOIN period_visits pv
      ON pv.user_id = pnu.id
      WHERE pv.visit_count >= :num_visits
    SQL

    ActiveRecord::Base.exec_sql(sql, period_start: period_start, period_end: period_end, num_visits: num_visits).count
  end

  def create_data(current, previous)
    {
      value: current,
      compare: previous,
    }
  end
end
