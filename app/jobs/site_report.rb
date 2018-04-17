module ::Jobs
  class SiteReport < ::Jobs::Scheduled
    every 1.day
    sidekiq_options 'retry' => true, 'queue' => 'critical'

    def execute(args)
      return unless DateTime.now.day == 1

      ::SiteReport::SiteReportMailer.report(args).deliver_now
    end
  end
end
