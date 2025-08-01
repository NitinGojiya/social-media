
# set :output, "log/cron.log"
# set :environment, "development"  # or "production" if deploying

# every 1.day, at: '12:00 am' do
#   runner "PostSchedulerJob.perform_later"
# end



set :output, {
  standard: "log/cron.log",
  error: "log/cron_error.log"
}
set :environment, "development"

every 1.minute do
  command "cd /home/nitin/ror_diffiter/social_media && bin/rails runner 'PostSchedulerJob.perform_later'"
end
