
set :output, "log/cron.log"
set :environment, "development"  # or "production" if deploying

every 1.day, at: '12:00 am' do
  runner "PostSchedulerJob.perform_later"
end


every 1.minute do
  runner <<~RUBY
    Post.where(status: 1, linkedin: 1).where("scheduled_at <= ?", Time.current).find_each do |post|
      LinkedInScheduledPostJob.perform_later(post.id)
    end
  RUBY
end
