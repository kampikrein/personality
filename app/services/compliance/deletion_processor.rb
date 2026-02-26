# frozen_string_literal: true

module Compliance
  # Processes a DeletionRequest by cascading through every piece of data
  # associated with the anonymous session and destroying it in the correct
  # dependency order. Each deletion is recorded in the AuditLog for
  # regulatory traceability.
  #
  # The cascade order:
  #   1. For each assessment: responses -> domain_scores -> insights (via profile) -> profiles
  #   2. Assessments themselves
  #   3. Consents
  #   4. The anonymous_session record
  #
  # Usage:
  #   result = Compliance::DeletionProcessor.new(deletion_request).call
  #   # => { success: true, deleted_counts: { responses: 20, ... } }
  #
  class DeletionProcessor
    attr_reader :deletion_request

    def initialize(deletion_request)
      @deletion_request = deletion_request
    end

    # @return [Hash] { success: Boolean, deleted_counts: Hash, error: String|nil }
    def call
      session = deletion_request.anonymous_session
      counts = Hash.new(0)

      ActiveRecord::Base.transaction do
        deletion_request.process!

        audit!("deletion_started", "DeletionRequest", deletion_request.id,
               session_token: session.session_token)

        # --- Per-assessment children ---
        session.assessments.find_each do |assessment|
          counts[:responses] += delete_and_audit!(
            assessment.responses, "Response", assessment_id: assessment.id
          )

          counts[:domain_scores] += delete_and_audit!(
            assessment.domain_scores, "DomainScore", assessment_id: assessment.id
          )

          if assessment.profile
            counts[:insights] += delete_and_audit!(
              assessment.profile.insights, "Insight", profile_id: assessment.profile.id
            )

            delete_single_and_audit!(assessment.profile, "Profile")
            counts[:profiles] += 1
          end
        end

        # --- Session-level profiles (not tied to an assessment) ---
        session.profiles.find_each do |profile|
          counts[:insights] += delete_and_audit!(
            profile.insights, "Insight", profile_id: profile.id
          )

          delete_single_and_audit!(profile, "Profile")
          counts[:profiles] += 1
        end

        # --- Assessments ---
        counts[:assessments] += delete_and_audit!(
          session.assessments, "Assessment", session_id: session.id
        )

        # --- Consents ---
        counts[:consents] += delete_and_audit!(
          session.consents, "Consent", session_id: session.id
        )

        # --- Session ---
        delete_single_and_audit!(session, "AnonymousSession")
        counts[:anonymous_sessions] = 1

        deletion_request.complete!

        audit!("deletion_completed", "DeletionRequest", deletion_request.id,
               deleted_counts: counts)
      end

      { success: true, deleted_counts: counts }
    rescue StandardError => e
      deletion_request.fail! unless deletion_request.status == "failed"

      audit!("deletion_failed", "DeletionRequest", deletion_request.id,
             error: e.message)

      { success: false, deleted_counts: counts, error: e.message }
    end

    private

    # Destroys all records in +relation+, logs each batch, and returns the count.
    def delete_and_audit!(relation, resource_type, metadata = {})
      ids = relation.pluck(:id)
      return 0 if ids.empty?

      relation.destroy_all

      audit!("records_deleted", resource_type, nil,
             metadata.merge(count: ids.size, ids: ids))

      ids.size
    end

    # Destroys a single record and logs it.
    def delete_single_and_audit!(record, resource_type)
      record_id = record.id
      record.destroy!

      audit!("record_deleted", resource_type, record_id)
    end

    def audit!(action, resource_type, resource_id, metadata = {})
      AuditLog.record!(
        action: action,
        actor_type: "System",
        actor_id: nil,
        resource_type: resource_type,
        resource_id: resource_id,
        metadata: metadata.merge(
          deletion_request_id: deletion_request.id,
          timestamp: Time.current.iso8601
        )
      )
    end
  end
end
