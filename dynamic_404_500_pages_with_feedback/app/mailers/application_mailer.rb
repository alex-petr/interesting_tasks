class ApplicationMailer < ActionMailer::Base
  default from: 'LiveVoice Notifier <notifier@livevoice.com>'
  layout 'mailer'
end
