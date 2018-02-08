module ::Jobs
  class SendSiteReport < ::Jobs::Scheduled
    every 1.day
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(args)
      puts "WE ARE EXECUTING THE SITE REPORT JOB"

      SiteReportMailer.report.deliver_now
    end
  end
end
