module SiteReportHelper
  def rtl?
    ["ar", "ur", "fa_IR", "he"].include? I18n.locale.to_s
  end

  def dir_for_locale
    rtl? ? 'rtl' : 'ltr'
  end

  def direction_for_locale
    rtl? ? 'right' : 'left'
  end

  def logo_url
    logo_url = SiteSetting.digest_logo_url
    logo_url = SiteSetting.logo_url if logo_url.blank? || logo_url =~ /\.svg$/i

    return nil if logo_url.blank? || logo_url =~ /\.svg$/i
    if logo_url !~ /http(s)?\:\/\//
      logo_url = "#{Discourse.base_url}#{logo_url}"
    end

    logo_url
  end

  def header_color
    "##{ColorScheme.hex_for_name('header_primary')}"
  end

  def header_bgcolor
    "##{ColorScheme.hex_for_name('header_background')}"
  end

  def anchor_color
    "##{ColorScheme.hex_for_name('tertiary')}"
  end

  def bg_color
    '#eeeeee'
  end

  def text_color
    '#222222'
  end

  def highlight_bgcolor
    '#2F70AC'
  end

  def highlight_color
    '#ffffff'
  end

  def body_bgcolor
    '#ffffff'
  end

  def body_color
    '#222222'
  end

  def report_date(months_ago)
    months_ago.month.ago.strftime('%B %Y')
  end

  def site_report_title(months_ago: 1)
    "#{I18n.t('site_report.stats_title')} #{report_date(months_ago)}"
  end

  def spacer_color(outer_count, inner_count = 0)
    outer_count == 0 && inner_count == 0 ? highlight_bgcolor : bg_color
  end

  def table_border_style(total_rows, current_row)
    unless total_rows - 1 == current_row
      "border-bottom:1px solid #dddddd;"
    end
  end

  def site_link
    "<a style='text-decoration:none;color:#{anchor_color}' href='#{Discourse.base_url}'>#{SiteSetting.title}</a>"
  end

  def site_report_link
    "<a style='text-decoration:none;color:#{anchor_color}' href='#{Discourse.base_url}/admin/site_settings/category/plugins?filter=site_report'>#{t 'site_report.here'}</a>"
  end

  def superscript(count)
    "<sup style='line-height:0;font-size:70%;vertical-align:top;mso-text-raise:50%'>[#{count}]</sup>"
  end

  def image_url(filename)
    "#{Discourse.base_url}/plugins/discourse-site-report/images/#{filename}"
  end

  def report_image_tag(filename, width: 300, alt: nil)
    "<img src='#{image_url(filename)}' width='#{width}' alt='#{alt}'>"
  end

  def highlight_side_spacer(row_count)
    "<td class='highlight-side-spacer' width='5%' style='background-color: #{spacer_color row_count};'>&nbsp;</td>"
  end

  def side_spacer
    "<td class='side-spacer' width='5%' style='background-color: #{bg_color};'>&nbsp;</td>"
  end

  def body_side_spacer
    "<td class='side-spacer' width='5%' style='background-color: #{body_bgcolor};'>&nbsp;</td>"
  end

  def blog_link(url)
    "#{t 'site_report.blog_link_text'} <a style='text-decoration:none;color:#{anchor_color}' href='#{url}'>#{t 'site_report.blog_link'}</a>."
  end

end
