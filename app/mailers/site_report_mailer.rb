require_relative '../helpers/site_report_helper'
require_dependency 'email/styles'

class SiteReport::SiteReportMailer < ActionMailer::Base
  attr_accessor :hide_count, :poor_health, :compare_threshold

  include Rails.application.routes.url_helpers
  include SiteReportHelper
  add_template_helper SiteReportHelper
  append_view_path Rails.root.join('plugins', 'discourse-site-report', 'app', 'views')
  default from: SiteSetting.notification_email, charset: 'UTF-8'

  def report(send_to: nil)
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    previous_start_date = 2.months.ago.beginning_of_month
    previous_end_date = 2.months.ago.end_of_month
    period_month = start_date.strftime('%B')
    days_in_period = end_date.day.to_i

    period_all_users = all_users(start_date)
    previous_all_users = all_users(previous_start_date)
    period_active_users = active_users(start_date, end_date)
    previous_active_users = active_users(previous_start_date, previous_end_date)
    period_engaged_users = engaged_users(start_date, end_date)
    previous_engaged_users = engaged_users(previous_start_date, previous_end_date)
    period_inactive_users = inactive_users(period_all_users, period_active_users)
    previous_inactive_users = inactive_users(previous_all_users, previous_active_users)
    period_dau = daily_average_users(days_in_period, period_active_users)
    period_new_contributors = new_contributors(start_date, end_date)
    previous_new_contributors = new_contributors(previous_start_date, previous_end_date)
    previous_dau = daily_average_users(30, previous_active_users)

    period_visits = user_visits(start_date, end_date)
    previous_period_visits = user_visits(previous_start_date, previous_end_date)
    period_signups = signups(start_date, end_date)
    previous_signups = signups(previous_start_date, previous_end_date)

    period_posts_read = posts_read(start_date, end_date)
    period_likes = likes(start_date, end_date)
    previous_likes = likes(previous_start_date, previous_end_date)
    period_flags = flags(start_date, end_date)
    previous_flags = flags(previous_start_date, previous_end_date)
    period_time_to_first_response = time_to_first_response(start_date, end_date)
    previous_time_to_first_response = time_to_first_response(previous_start_date, previous_end_date)
    period_average_time_onsite = average_time_onsite(start_date, end_date)
    previous_average_time_onsite = average_time_onsite(previous_start_date, previous_end_date)
    period_no_response = topics_with_no_response(end_date)
    previous_no_response = topics_with_no_response(previous_end_date)
    period_accepted_solutions = accepted_solutions(start_date, end_date)
    previous_accepted_solutions = accepted_solutions(previous_start_date, previous_end_date)

    period_topics = topics_created(start_date, end_date)
    previous_topics = topics_created(previous_start_date, previous_end_date)
    period_posts = posts_created(start_date, end_date)
    previous_posts = posts_created(previous_start_date, previous_end_date)

    header_metadata = [
      { key: 'site_report.active_users', value: period_active_users },
      { key: 'site_report.posts_created', value: period_posts },
      { key: 'site_report.posts_read', value: period_posts_read }
    ]

    health_fields = [
      field_hash('new_users', period_signups, previous_signups, has_description: true),
      field_hash('engaged_users', period_engaged_users, previous_engaged_users, has_description: true),
      field_hash('topics_created', period_topics, previous_topics, has_description: false),
      field_hash('inactive_users', period_inactive_users, previous_inactive_users, has_description: true, negative_compare: true),
      field_hash('new_contributors', period_new_contributors, previous_new_contributors, has_description: true),
      field_hash('health', health(period_dau, period_active_users), health(previous_dau, previous_active_users), has_description: true)
    ].compact

    activity_fields = [
      field_hash('user_visits', period_visits, previous_period_visits, has_description: true),
      field_hash('posts_created', period_posts, previous_posts, has_description: false),
      field_hash('response_time', period_time_to_first_response, previous_time_to_first_response, has_description: true, negative_compare: true),
      field_hash('average_time_onsite', period_average_time_onsite, previous_average_time_onsite, has_description: true),
      field_hash('unanswered_topics', period_no_response, previous_no_response, has_description: true, negative_compare: true),
      field_hash('posts_liked', period_likes, previous_likes, has_description: false),
      field_hash('posts_flagged', period_flags, previous_flags, has_description: false, never_hide: true),
    ]

    if period_accepted_solutions > 0 || previous_accepted_solutions > 0
      activity_fields << field_hash('solutions', period_accepted_solutions, previous_accepted_solutions, has_description: true)
    end

    activity_fields = activity_fields.compact

    activity_data = {
      title_key: 'site_report.activity_section_title',
      fields: activity_fields
    }

    @poor_health = health_fields.any? ? false : true
    health_data =  {
      title_key: 'site_report.health_section_title',
      fields: health_fields
    }

    data_array = []
    [health_data, activity_data].each do |data|
      data_array << data if data[:fields].any?
    end

    subject = site_report_title
    report_type = get_report_type

    # The plugin can eventually include a :tips report for sites that are not doing well. For now, the report is only
    # sent when the site's data is good.

    if :stats == report_type
      @data = {
        period_month: period_month,
        title: subject,
        subject: subject,
        header_metadata: header_metadata,
        data_array: data_array,
        report_type: report_type
      }

      admin_emails = User.where(admin: true).map(&:email).select { |e| e.include?('@') }
      admin_emails.delete_if { |x| /@discourse.org$/ =~ x }

      mail_to = send_to ? send_to : admin_emails
      mail(to: mail_to, subject: subject)
    end
  end

  private

  def initialize
    super
    @hide_count = 0
    @compare_threshold = -5
  end

  def get_report_type
    @poor_health || @hide_count > 3 ? :tips : :stats
  end

  def field_hash(key, current, previous, opts = {})
    compare_value = compare(current, previous)
    hide = false

    unless opts[:never_hide]
      hide = opts[:negative_compare] ? compare_value && compare_value > -@compare_threshold : compare_value && compare_value < @compare_threshold
    end

    # Return nil if the field is to be hidden.
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

    (((current - previous) * 100.0) / previous).round(1)
  end

  def format_compare(val)
    return I18n.t("site_report.no_data_available") if val.nil?

    sprintf("%+d%", val)
  end

  def active_users(period_start, period_end)
    UserVisit.where("visited_at >= :period_start AND visited_at <= :period_end",
                    period_start: period_start,
                    period_end: period_end).pluck(:user_id).uniq.count
  end

  def daily_average_users(days_in_period, active_users)
    (active_users / days_in_period.to_f).round(1)
  end

  def health(dau, mau)
    if mau > 0
      (dau * 100.0/mau).round(1)
    else
      0
    end
  end

  def all_users(end_date)
    User.where("created_at <= ?", end_date).count
  end

  def user_visits(start_date, end_date)
    UserVisit.where("visited_at >= :start_date AND visited_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def signups(start_date, end_date)
    User.where("created_at >= :start_date AND created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def inactive_users(all_users, active_users)
    all_users - active_users
  end

  def unique_liker_ids(start_date, end_date)
    PostAction.where("created_at >= :start_date AND created_at <= :end_date AND post_action_type_id = :like_type",
                     start_date: start_date,
                     end_date: end_date,
                     like_type: PostActionType.types[:like]).pluck(:user_id).uniq
  end

  def unique_poster_ids(start_date, end_date)
    Post.public_posts.where("posts.created_at >= :start_date AND posts.created_at <= :end_date", start_date: start_date, end_date: end_date).pluck(:user_id).uniq
  end

  def engaged_users(start_date, end_date)
    (unique_liker_ids(start_date, end_date) + unique_poster_ids(start_date, end_date)).uniq.count
  end

  def new_contributors(period_start, period_end)
    previous_contributors = User.joins(:posts).where("posts.created_at < :period_start AND users.id > 0", period_start: period_start).pluck(:id).uniq
    current_contributors = User.joins(:posts).where("posts.created_at >= :period_start AND posts.created_at <= :period_end AND users.id > 0", period_start: period_start, period_end: period_end).pluck(:id).uniq
    (current_contributors - previous_contributors).count
  end

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
    Topic.time_to_first_response_total(start_date: start_date, end_date: end_date).round(1)
  end

  def topics_with_no_response(end_date)
    sql = <<-SQL
WITH topics_and_first_replies AS (
SELECT
MIN(p.post_number) AS first_reply,
MIN(p.created_at) AS created_at
FROM topics t
LEFT JOIN posts p
ON p.topic_id = t.id
AND p.user_id != t.user_id
AND p.deleted_at IS NULL
AND p.post_type = 1
WHERE t.archetype = 'regular'
AND t.deleted_at IS NULL
GROUP BY t.id
)
SELECT COUNT(*) AS count
FROM topics_and_first_replies tfr
WHERE tfr.first_reply IS NULL
OR tfr.created_at > '#{end_date}'
    SQL

    ActiveRecord::Base.connection.execute(sql).first['count']
  end

  def average_time_onsite(start_date, end_date)
    visits = UserVisit.where("visited_at >= :start_date AND visited_at <= :end_date", start_date: start_date, end_date: end_date).pluck(:user_id, :time_read)
    users = []
    readtimes = []
    visits.each do |visit|
      users << visit[0]
      readtimes << visit[1]
    end

    ((readtimes.sum / users.uniq.count) / 60.0).round(1)
  end

  def topics_created(start_date, end_date)
    Topic.listable_topics.where("topics.created_at >= :start_date AND topics.created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def posts_created(start_date, end_date)
    Post.public_posts.where("posts.created_at >= :start_date AND posts.created_at <= :end_date", start_date: start_date, end_date: end_date).count
  end

  def accepted_solutions(start_date, end_date)
    TopicCustomField.where("name = 'accepted_answer_post_id' AND created_at >= :start_date AND created_at <= :end_date",
                           start_date: start_date,
                           end_date: end_date).count
  end
end
