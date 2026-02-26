module Admin
  class AuditLogsController < BaseController
    # GET /admin/audit_logs
    # Lists audit log entries, most recent first, with optional filtering.
    def index
      @audit_logs = AuditLog.order(created_at: :desc)
      @audit_logs = @audit_logs.where(action: params[:action_filter]) if params[:action_filter].present?
      @audit_logs = @audit_logs.where(auditable_type: params[:type_filter]) if params[:type_filter].present?
    end

    # GET /admin/audit_logs/:id
    # Shows full details for a specific audit log entry, including
    # the change diff and metadata.
    def show
      @audit_log = AuditLog.find(params[:id])
    end
  end
end
