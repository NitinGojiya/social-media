
set :output, "log/cron.log"
set :environment, "development"  # or "production" if deploying

every 1.day, at: '12:00 am' do
  runner "PostSchedulerJob.perform_later"
end
