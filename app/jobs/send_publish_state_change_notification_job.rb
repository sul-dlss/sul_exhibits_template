# frozen_string_literal: true

##
# A background job to send notifications via the ExhibitBot about the published state of an exhibit changing
class SendPublishStateChangeNotificationJob < ApplicationJob
  def perform(exhibit:, published:)
    ExhibitBot.message(text: message_text(exhibit:, published:))
  end

  private

  def message_text(exhibit:, published:)
    published_text = published ? 'published' : 'un-published'
    date_text = I18n.l(Time.zone.parse(exhibit.updated_at.to_s), format: :long)

    <<-MSG_TEXT.strip_heredoc
      📢 *Spotlight exhibit #{published_text}: #{exhibit.title}* 📢
      > Spotlight exhibit #{exhibit.title} #{published_text} at #{date_text}
      > #{exhibit_url(exhibit)}
    MSG_TEXT
  end

  def exhibit_url(exhibit)
    url_helpers = Spotlight::Engine.routes.url_helpers
    url_helpers.exhibit_url(exhibit, host: Settings.action_mailer.default_url_options.host)
  end
end
