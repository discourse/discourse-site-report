require_dependency 'report'
require_relative '../helpers/site_report_helper'

class SiteReportMailer < ActionMailer::Base
  attr_accessor :hide_count, :hide_health_section, :hide_users_section, :hide_content_section, :hide_user_actions_section
  @@hide_count = 0
  @@hide_health_section = true
  @@hide_users_section = true
  @@hide_content_section = true
  @@hide_user_actions_section = true

  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include SiteReportHelper
  helper :application
  add_template_helper SiteReportHelper
  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email

  def report
    subject = site_report_title
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    previous_start_date = 2.months.ago.beginning_of_month
    previous_end_date = 2.months.ago.end_of_month
    period_month = start_date.strftime('%B')
    days_in_period = end_date.day.to_i

    # visits = Report.find(:visits, start_date: start_date, end_date: end_date)
    period_visits = user_visits(start_date, end_date)
    prev_period_visits = user_visits(previous_start_date, previous_end_date)
    #mobile_visits = Report.find(:mobile_visits, start_date: start_date, end_date: end_date)
    period_mobile_visits = user_visits_mobile(start_date, end_date)
    prev_mobile_visits = user_visits_mobile(previous_start_date, previous_end_date)
    period_signups = signups(start_date, end_date)
    prev_signups = signups(previous_start_date, previous_end_date)
    # signups = Report.find(:signups, start_date: start_date, end_date: end_date)
    # profile_views = Report.find(:profile_views, start_date: start_date, end_date: end_date)
    # topics = Report.find(:topics, start_date: start_date, end_date: end_date)
    period_topics = topics_created(start_date, end_date)
    prev_topics = topics_created(previous_start_date, previous_end_date)
    posts = Report.find(:posts, start_date: start_date, end_date: end_date)
    time_to_first_response = Report.find(:time_to_first_response, start_date: start_date, end_date: end_date)
    topics_with_no_response = Report.find(:topics_with_no_response, start_date: start_date, end_date: end_date)
    emails = Report.find(:emails, start_date: start_date, end_date: end_date)
    flags = Report.find(:flags, start_date: start_date, end_date: end_date)
    likes = Report.find(:likes, start_date: start_date, end_date: end_date)
    accepted_solutions = Report.find(:accepted_solutions, start_date: start_date, end_date: end_date)

    active_users_current = active_users(start_date, end_date)
    active_users_previous = active_users(previous_start_date, previous_end_date)
    daily_average_users_current = daily_average_users(days_in_period, active_users_current)
    daily_average_users_previous = daily_average_users(30, active_users_previous)
    repeat_new_users_current = repeat_new_users start_date, end_date, 2
    repeat_new_users_previous = repeat_new_users previous_start_date, previous_end_date, 2
    posts_read_current = posts_read(start_date, end_date)
    posts_read_previous = posts_read(previous_start_date, previous_end_date)

    # @data[:repeat_new_users] = create_data(repeat_new_users, previous_repeat_new_users)

    header_metadata = [
      {key: 'site_report.active_users', value: active_users_current},
      {key: 'site_report.posts', value: total_from_data(posts.data)},
      {key: 'site_report.posts_read', value: posts_read_current}

    ]

    health_fields = [
      health_field_hash('active_users', active_users_current, active_users_previous, has_description: true),
      health_field_hash( 'daily_active_users', daily_average_users_current, daily_average_users_previous, has_description: true),
      health_field_hash('health', health(daily_average_users_current, active_users_current), health(daily_average_users_previous, active_users_previous), has_description: true)
    ]

    health_data =  {
      title_key: 'site_report.health_section_title',
      hide_section: @@hide_health_section,
      fields: health_fields
    }

    user_fields = [
      users_field_hash('all_users', all_users(end_date), all_users(previous_end_date), has_description: true),
      # field_hash('user_visits', total_from_data(visits.data), visits.prev30Days, has_description: true),
      users_field_hash('user_visits', period_visits, prev_period_visits, has_description: true),
      users_field_hash('mobile_visits', period_mobile_visits, prev_mobile_visits, has_description: true),
      users_field_hash('new_users', period_signups, prev_signups, has_description: true),
      users_field_hash('repeat_new_users', repeat_new_users_current, repeat_new_users_previous, has_description: true),
    ]

    user_data = {
      title_key: 'site_report.users_section_title',
      hide_section: @@hide_users_section,
      fields: user_fields
    }

    user_action_fields = [
      user_actions_field_hash('posts_read', posts_read_current, posts_read_previous, has_description: true),
      user_actions_field_hash('posts_liked', total_from_data(likes.data), likes.prev30Days, has_description: true),
      user_actions_field_hash('posts_flagged', total_from_data(flags.data), flags.prev30Days, has_description: true),
      user_actions_field_hash('response_time', average_from_data(time_to_first_response.data), time_to_first_response.prev30Days, has_description: true),
    ]

    if accepted_solutions
      user_action_fields << user_actions_field_hash('solutions', total_from_data(accepted_solutions.data), accepted_solutions.prev30Days, has_description: true)
    end

    user_action_data = {
      title_key: 'site_report.user_actions_title',
      hide_section: @@hide_user_actions_section,
      fields: user_action_fields
    }

    content_fields = [
      content_field_hash('topics_created', period_topics, prev_topics, has_description: true),
      content_field_hash('posts_created', total_from_data(posts.data), posts.prev30Days, has_description: true),
      content_field_hash('emails_sent', total_from_data(emails.data), emails.prev30Days, has_description: true),
    ]

    content_data = {
      title_key: 'site_report.content_section_title',
      hide_section: @@hide_content_section,
      fields: content_fields
    }

    data_array = [
      health_data,
      user_data,
      user_action_data,
      content_data,
    ]

    @data = {
      period_month: period_month,
      title: subject,
      subject: subject,
      header_metadata: header_metadata,
      data_array: data_array
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}
    mail(to: admin_emails, subject: subject)
  end

  def user_visits(start_date, end_date)
    UserVisit.where("visited_at >= :start_date AND visited_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def user_visits_mobile(start_date, end_date)
    UserVisit.where("visited_at >= :start_date AND visited_at <= :end_date AND mobile = true", start_date: start_date, end_date: end_date).count
  end

  def signups(start_date, end_date)
    User.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def topics_created(start_date, end_date)
    Topic.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
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

  def all_users(end_date)
    User.where("created_at <= ?", end_date).count
  end

  def active_users(period_start, period_end)
    UserVisit.where("visited_at >= :period_start AND visited_at <= :period_end",
                    period_start: period_start,
                    period_end: period_end).pluck(:user_id).uniq.count
  end

  def posts_read(period_start, period_end)
    UserVisit.where("visited_at >= :period_start AND visited_at <= :period_end",
                    period_start: period_start,
                    period_end: period_end).pluck(:posts_read).sum
  end

  # todo: validate
  def daily_average_users(days_in_period, active_users)
    (active_users / days_in_period.to_f).round(2)
  end

  def health(dau, mau)
    if mau > 0
      (dau * 100.0/mau).round(2)
    else
      0
    end
  end

  def health_field_hash(key, current, previous, opts = {})
    field = field_hash(key, current, previous, opts)

    @@hide_health_section = false unless field[:hide]

    field
  end

  def users_field_hash(key, current, previous, opts = {})
    field = field_hash(key, current, previous, opts)

    @@hide_users_section = false unless field[:hide]

    field
  end

  def user_actions_field_hash(key, current, previous, opts = {})
    field = field_hash(key, current, previous, opts)

    @@hide_user_actions_section = false unless field[:hide]

    field
  end

  def content_field_hash(key, current, previous, opts = {})
    field = field_hash(key, current, previous, opts)

    @@hide_content_section = false unless field[:hide]

    field
  end

  def field_hash(key, current, previous, opts = {})
    compare_value = compare(current, previous)
    # todo: set this to a sane value
    hide = opts[:negative_compare] ? compare_value && compare_value > 10.0 : compare_value && compare_value < -1000.0
    @@hide_count += 1 if hide

    {
      key: "site_report.#{key}",
      value: current,
      compare: format_compare(compare_value),
      description_key: opts[:has_description] ? "site_report.descriptions.#{key}" : nil,
      hide: hide
    }
  end

  def compare(current, previous)
    # return I18n.t("site_report.no_data_available") if previous == 0
    return nil if previous == 0
    return 0 if current == previous

    (((current - previous) * 100.0) / previous).round(2)

    # sprintf("%+d%", diff)
  end

  def format_compare(val)
    return I18n.t("site_report.no_data_available") if val.nil?

    sprintf("%+d%", val)
  end

  def total_from_data(data)
    data.each.pluck(:y).sum
  end

  # todo: validate!
  def average_from_data(data)
    responses = data.count
    total = data.each.pluck(:y).sum
    (total / responses).round(2)
  end
end
