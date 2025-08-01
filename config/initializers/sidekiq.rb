require 'sidekiq'
require 'sidekiq-cron'

Sidekiq::Cron::Job.load_from_hash!({
  'post_scheduler_job' => {
    'cron'  => '* * * * *', # every minute
    'class' => 'PostSchedulerJob'
  }
})
