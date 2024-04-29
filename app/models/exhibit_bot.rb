# frozen_string_literal: true

##
# A wrapper class around the Slack Web Client.
# All public methods are delegated through the class itself so things like
# ExhibitBot.message(text: 'My Message Content') will simply work anywhere.
class ExhibitBot
  class << self
    delegate :message, to: :new
  end

  def message(channel: default_channel, as_user: true, text:)
    client.chat_postMessage(channel:, as_user:, text:)
  end

  private

  def default_channel
    Settings.slack_notifications.default_channel
  end

  def client
    @client ||= if FeatureFlags.new.slack_notifications?
                  Slack::Web::Client.new
                else
                  NullClient.new
                end
  end

  # rubocop: disable Naming/MethodName
  # NullObject pattern returned when we're not configured to send slack notifications
  class NullClient
    # noop
    def chat_postMessage(*args); end
  end
  # rubocop: enable Naming/MethodName
end
