module ::Jobs
  class SiteReport < ::Jobs::Scheduled
    every 1.day
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(args)
      ::SiteReport::SiteReportMailer.report.deliver_now
    end
  end
end
