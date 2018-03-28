module ::Jobs
  class SendSiteReport < ::Jobs::Scheduled
    every 1.day
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(args)
      SiteReportMailer.report.deliver_now
    end
  end
end
