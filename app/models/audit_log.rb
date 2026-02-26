class AuditLog < ApplicationRecord
  validates :action, presence: true

  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :recent, -> { order(created_at: :desc).limit(100) }

  def self.record!(action:, actor_type: nil, actor_id: nil, resource_type: nil, resource_id: nil, metadata: {})
    create!(
      action: action,
      actor_type: actor_type,
      actor_id: actor_id,
      resource_type: resource_type,
      resource_id: resource_id,
      metadata: metadata
    )
  end
end
