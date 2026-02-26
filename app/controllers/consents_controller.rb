class ConsentsController < ApplicationController
  # GET /consents/new
  # Renders the consent form where the user can review and accept
  # data processing terms before or during an assessment.
  def new
    @consent = Consent.new
  end

  # POST /consents
  # Records the user's consent with a timestamp and the specific
  # version of the consent text they agreed to.
  def create
    @consent = current_session.consents.build(consent_params)
    @consent.granted_at = Time.current
    @consent.consent_version ||= "1.0"
    @consent.consent_text_snapshot ||= default_consent_text(@consent.consent_type)

    if @consent.save
      redirect_to root_path, notice: "동의가 기록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /consents/:id
  # Shows the details of a specific consent record, including what
  # was agreed to and when.
  def show
    @consent = current_session.consents.find(params[:id])
  end

  # PATCH /consents/:id
  # Allows the user to update (withdraw or modify) a previously
  # granted consent.
  def update
    @consent = current_session.consents.find(params[:id])

    if @consent.update(consent_params)
      redirect_to consent_path(@consent), notice: "Consent updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def consent_params
    params.require(:consent).permit(:consent_type, :version, :granted)
  end

  def default_consent_text(type)
    case type
    when "data_processing"
      "검사 응답 데이터를 처리하여 성격 프로필을 생성합니다."
    when "analytics"
      "서비스 개선을 위한 익명화된 통계 분석에 활용합니다."
    else
      "데이터 처리에 동의합니다."
    end
  end
end
