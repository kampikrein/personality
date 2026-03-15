module Admin
  class QuestionSetsController < BaseController
    before_action :set_question_set, only: [:show, :edit, :update, :destroy]

    # GET /admin/question_sets
    def index
      @question_sets = QuestionSet.order(created_at: :desc)
    end

    # GET /admin/question_sets/:id
    def show
    end

    # GET /admin/question_sets/new
    def new
      @question_set = QuestionSet.new
    end

    # GET /admin/question_sets/:id/edit
    def edit
    end

    # POST /admin/question_sets
    def create
      @question_set = QuestionSet.new(question_set_params)

      if @question_set.save
        redirect_to admin_question_set_path(@question_set),
                    notice: "Question set created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH /admin/question_sets/:id
    def update
      if @question_set.update(question_set_params)
        redirect_to admin_question_set_path(@question_set),
                    notice: "Question set updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/question_sets/:id
    def destroy
      @question_set.destroy
      redirect_to admin_question_sets_path,
                  notice: "Question set deleted."
    end

    private

    def set_question_set
      @question_set = QuestionSet.find(params[:id])
    end

    def question_set_params
      params.require(:question_set).permit(:name, :version, :active)
    end
  end
end
