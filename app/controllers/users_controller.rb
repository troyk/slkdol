class UsersController < ApplicationController
  skip_before_action :require_current_user, only: [:signin]

  def signin
    if params[:username] && params[:password]
      self.current_user = params[:username]
      if self.current_user.nil?
        flash.now[:alert] = "invalid username"
      elsif params[:password] != ENV["SLKDOL_PASSWORD"] &&  params[:password] != ENV["SLKDOL_ADMIN"]  
        self.current_user = nil
        flash.now[:alert] = "invalid password"
      end
    end
    if self.current_user?
      redirect_to "/time"
      return
    end
    render layout: false
  end
end
