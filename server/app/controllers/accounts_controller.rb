class AccountsController < ApplicationController
  # GET /account/new
  # Renders the account creation form so an anonymous user can optionally
  # claim their session by creating a persistent account.
  def new
    @user = User.new
  end

  # POST /account
  # Creates a User record and links it to the current anonymous session,
  # allowing the user to access their results later.
  def create
    @user = User.new(account_params)

    if @user.save
      current_session.update!(user: @user)
      redirect_to root_path, notice: "Account created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
