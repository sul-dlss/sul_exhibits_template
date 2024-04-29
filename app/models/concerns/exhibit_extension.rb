# frozen_string_literal: true

##
# A concern to be mixed into the Spotlight::Exhibit
# class in order to add application specific behavior
module ExhibitExtension
  extend ActiveSupport::Concern

  included do
    has_one :viewer, dependent: :delete

    after_update :send_publish_state_change_notification
    after_save :index_exhibit_metadata

    scope :discoverable, -> { where.not(slug: Settings.nondiscoverable_exhibit_slugs) }
  end

  ##
  # If an Exhibit doesn't already have a Viewer setup, create one.
  # @return [Viewer]
  def required_viewer
    return viewer if viewer.present?

    Viewer.create(exhibit: self)
  end

  private

  def send_publish_state_change_notification
    return unless saved_changes.key?('published')

    SendPublishStateChangeNotificationJob.perform_later(exhibit: self, published:)
  end

  def index_exhibit_metadata
    return unless FeatureFlags.new.exhibits_index?

    if published?
      IndexExhibitMetadataJob.perform_later(exhibit: self, action: 'add')
    elsif saved_change_to_published?
      IndexExhibitMetadataJob.perform_later(exhibit: self, action: 'delete')
    end
  end
end
