class DeletionRequestsController < ApplicationController
  # GET /deletion_requests/new
  # Renders the data deletion request form where the user can request
  # removal of all their data in compliance with privacy regulations.
  def new
    @deletion_request = DeletionRequest.new
  end

  # POST /deletion_requests
  # Creates a DeletionRequest record tied to the current session.
  # The actual deletion is processed asynchronously by a background job.
  def create
    @deletion_request = current_session.deletion_requests.build

    if @deletion_request.save
      # In production: DeletionJob.perform_later(@deletion_request.id)
      redirect_to root_path, notice: "삭제 요청이 접수되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /deletion_requests/:id
  # Shows the current status of a deletion request so the user can
  # track whether their data has been removed.
  def show
    @deletion_request = current_session.deletion_requests.find(params[:id])
  end

  private
end
