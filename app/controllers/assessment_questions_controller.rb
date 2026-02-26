class AssessmentQuestionsController < ApplicationController
  before_action :set_assessment
  before_action :set_question

  # GET /assessments/:assessment_id/questions/:id
  # Renders the current question inside a Turbo Frame so the assessment
  # page can stream questions without a full page reload.
  def show
    @response = @assessment.responses.find_or_initialize_by(question: @question)
  end

  # PATCH /assessments/:assessment_id/questions/:id
  # Saves the user's Response (value, response_time_ms, sequence_number),
  # advances the assessment's current question index, and returns the
  # next question via Turbo Frame — or redirects to submit when done.
  def update
    response = @assessment.responses.find_or_initialize_by(question: @question)

    response.assign_attributes(
      response_params.merge(sequence_number: @assessment.current_question_index)
    )

    if response.save
      next_question = @assessment.advance_to_next_question!

      if next_question
        redirect_to assessment_question_path(@assessment, next_question)
      else
        redirect_to assessment_path(@assessment)
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_assessment
    @assessment = current_session.assessments.find(params[:assessment_id])
  end

  def set_question
    @question = @assessment.question_set.questions.find(params[:id])
  end

  def response_params
    params.require(:response).permit(:value, :response_time_ms)
  end
end
