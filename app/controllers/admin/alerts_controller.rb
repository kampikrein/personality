module Admin
  class AlertsController < BaseController
    before_action :set_alert, only: [:show, :update]

    # GET /admin/alerts
    # Lists all monitoring alerts, most recent first.
    def index
      @alerts = Alert.order(created_at: :desc)
    end

    # GET /admin/alerts/:id
    # Shows details for a specific alert.
    def show
    end

    # PATCH /admin/alerts/:id
    # Updates an alert's status (e.g., acknowledge, resolve, dismiss).
    def update
      if @alert.update(alert_params)
        redirect_to admin_alert_path(@alert),
                    notice: "Alert updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_alert
      @alert = Alert.find(params[:id])
    end

    def alert_params
      params.require(:alert).permit(:status, :resolved_at, :notes)
    end
  end
end
