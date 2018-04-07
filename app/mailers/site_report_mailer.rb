require_relative '../helpers/site_report_helper'
require_dependency 'email/styles'

class SiteReport::SiteReportMailer < ActionMailer::Base
  attr_accessor :hide_count, :poor_health, :compare_threshold

  include Rails.application.routes.url_helpers
  include SiteReportHelper
  add_template_helper SiteReportHelper
  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email

  def report(send_to: nil)

    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    previous_start_date = 2.months.ago.beginning_of_month
    previous_end_date = 2.months.ago.end_of_month
    period_month = start_date.strftime('%B')
    days_in_period = end_date.day.to_i

    period_active_users = active_users(start_date, end_date)
    prev_active_users = active_users(previous_start_date, previous_end_date)
    period_dau = daily_average_users(days_in_period, period_active_users)
    prev_dau = daily_average_users(30, prev_active_users)

    period_visits = user_visits(start_date, end_date)
    prev_period_visits = user_visits(previous_start_date, previous_end_date)
    period_mobile_visits = user_visits_mobile(start_date, end_date)
    prev_mobile_visits = user_visits_mobile(previous_start_date, previous_end_date)
    period_signups = signups(start_date, end_date)
    prev_signups = signups(previous_start_date, previous_end_date)
    period_repeat_new_users = repeat_new_users(start_date, end_date, 2)
    prev_repeat_new_users = repeat_new_users(previous_start_date, previous_end_date, 2)

    period_posts_read = posts_read(start_date, end_date)
    prev_posts_read = posts_read(previous_start_date, previous_end_date)
    period_likes = likes(start_date, end_date)
    prev_likes = likes(previous_start_date, previous_end_date)
    period_flags = flags(start_date, end_date)
    prev_flags = flags(previous_start_date, previous_end_date)
    period_time_to_first_response = time_to_first_response(start_date, end_date)
    prev_time_to_first_response = time_to_first_response(previous_start_date, previous_end_date)
    period_accepted_solutions = accepted_solutions(start_date, end_date)
    prev_accepted_solutions = accepted_solutions(previous_start_date, previous_end_date)

    period_topics = topics_created(start_date, end_date)
    prev_topics = topics_created(previous_start_date, previous_end_date)
    period_posts = posts_created(start_date, end_date)
    prev_posts = posts_created(previous_start_date, previous_end_date)
    period_emails_sent = emails_sent(start_date, end_date)
    prev_emails_sent = emails_sent(previous_start_date, previous_end_date)

    header_metadata = [
      { key: 'site_report.active_users', value: period_active_users },
      { key: 'site_report.posts', value: period_posts },
      { key: 'site_report.posts_read', value: period_posts_read }

    ]

    health_fields = [
      field_hash('active_users', period_active_users, prev_active_users, has_description: true),
      field_hash( 'daily_active_users', period_dau, prev_dau, has_description: true),
      field_hash('health', health(period_dau, period_active_users), health(prev_dau, prev_active_users), has_description: true)
    ].compact

    @poor_health = health_fields.any? ? false : true
    health_data =  {
      title_key: 'site_report.health_section_title',
      fields: health_fields
    }

    user_fields = [
      field_hash('all_users', all_users(end_date), all_users(previous_end_date), has_description: true),
      field_hash('user_visits', period_visits, prev_period_visits, has_description: true),
      field_hash('mobile_visits', period_mobile_visits, prev_mobile_visits, has_description: true),
      field_hash('new_users', period_signups, prev_signups, has_description: true),
      field_hash('repeat_new_users', period_repeat_new_users, prev_repeat_new_users, has_description: true),
    ].compact

    user_data = {
      title_key: 'site_report.users_section_title',
      fields: user_fields
    }

    user_action_fields = [
      field_hash('posts_read', period_posts_read, prev_posts_read, has_description: false),
      field_hash('posts_liked', period_likes, prev_likes, has_description: false),
      field_hash('posts_flagged', period_flags, prev_flags, has_description: false),
      field_hash('response_time', period_time_to_first_response, prev_time_to_first_response, has_description: true),
    ]

    if period_accepted_solutions > 0 || prev_accepted_solutions > 0
      user_action_fields << field_hash('solutions', period_accepted_solutions, prev_accepted_solutions, has_description: true)
    end

    user_action_fields = user_action_fields.compact

    user_action_data = {
      title_key: 'site_report.user_actions_title',
      fields: user_action_fields
    }

    content_fields = [
      field_hash('topics_created', period_topics, prev_topics, has_description: false),
      field_hash('posts_created', period_posts, prev_posts, has_description: false),
      field_hash('emails_sent', period_emails_sent, prev_emails_sent, has_description: false),
    ].compact

    content_data = {
      title_key: 'site_report.content_section_title',
      fields: content_fields
    }

    data_array = []
    [health_data, user_data, user_action_data, content_data].each do |data|
      data_array << data if data[:fields].any?
    end

    subject = site_report_title(1)

    @data = {
      period_month: period_month,
      title: subject,
      subject: subject,
      header_metadata: header_metadata,
      data_array: data_array,
      report_type: report_type
    }

    admin_emails = User.where(admin: true).map(&:email).select { |e| e.include?('@') }
    mail_to = send_to ? send_to : admin_emails
    mail(to: mail_to, subject: subject)
  end

  private

  def initialize
    super
    @hide_count = 0
    @compare_threshold = -10
    @alternate_report = false
  end

  def report_type
    @poor_health || @hide_count > 5 ? :tips : :stats
  end

  def field_hash(key, current, previous, opts = {})
    compare_value = compare(current, previous)
    hide = opts[:negative_compare] ? compare_value && compare_value > -@compare_threshold : compare_value && compare_value < @compare_threshold
    if hide
      @hide_count += 1
      nil
    else
      {
        key: "site_report.#{key}",
        value: current,
        compare: format_compare(compare_value),
        description_key: opts[:has_description] ? "site_report.descriptions.#{key}" : nil,
      }
    end
  end

  def compare(current, previous)
    return nil if previous == 0
    return 0 if current == previous

    (((current - previous) * 100.0) / previous).round(2)
  end

  def format_compare(val)
    return I18n.t("site_report.no_data_available") if val.nil?

    sprintf("%+d%", val)
  end

  # Health

  def active_users(period_start, period_end)
    UserVisit.where("visited_at >= :period_start AND visited_at <= :period_end",
                    period_start: period_start,
                    period_end: period_end).pluck(:user_id).uniq.count
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

  # Users

  def all_users(end_date)
    User.where("created_at <= ?", end_date).count
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

  # User Actions

  def posts_read(period_start, period_end)
    UserVisit.where("visited_at >= :period_start AND visited_at <= :period_end",
                    period_start: period_start,
                    period_end: period_end).pluck(:posts_read).sum
  end

  def likes(start_date, end_date)
    PostAction.where("created_at >= :start_date AND created_at <= :end_date AND post_action_type_id = :like_type",
                     start_date: start_date,
                     end_date: end_date,
                     like_type: PostActionType.types[:like]).count
  end

  def flags(start_date, end_date)
    PostAction.where("created_at >= :start_date AND created_at <= :end_date AND post_action_type_id IN (:flag_actions)",
                     start_date: start_date,
                     end_date: end_date,
                     flag_actions: PostActionType.flag_types_without_custom.values).count
  end

  def time_to_first_response(start_date, end_date)
    Topic.time_to_first_response_total(start_date: start_date, end_date: end_date)
  end

  # Todo: this isn't being used
  def topics_with_no_response(start_date, end_date)
    Topic.with_no_response_total(start_date: start_date, end_date: end_date)
  end

  # Content Created

  def topics_created(start_date, end_date)
    Topic.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def posts_created(start_date, end_date)
    Post.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def emails_sent(start_date, end_date)
    EmailLog.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def accepted_solutions(start_date, end_date)
    TopicCustomField.where("name = 'accepted_answer_post_id' AND created_at >= :start_date AND created_at <= :end_date",
                           start_date: start_date,
                           end_date: end_date).count
  end
end
