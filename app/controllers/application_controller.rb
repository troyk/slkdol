class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token
  before_filter :require_current_user

  def self.users
    if @users_src != ENV["SLKDOL_USERNAMES"]
      @users_src = ENV["SLKDOL_USERNAMES"]
      @users = @users_src.split(" ").map{|uname| uname.humanize}.select{|uname| uname.present?}
    end
    @users
  end

  # authentication
  def current_user
    return @current_user unless @current_user.nil?
    if cookies['slkdol']
      if self.class.users.include?(cookies['slkdol'])
        @current_user = cookies['slkdol']
      elsif ENV["SLKDOL_ADMIN"].strip.present? && cookies['slkdol'] == ENV["SLKDOL_ADMIN"]
        @current_user = cookies['slkdol']
      end
    end
    @current_user
  end
  helper_method :current_user
  def current_user?; current_user.present?; end

  def current_user=(u)
    if u.strip.present?
      if self.class.users.include?(u.humanize)
        @current_user = cookies['slkdol'] = u.humanize
      elsif u == ENV["SLKDOL_ADMIN"] # case sensitive
        @current_user = cookies['slkdol'] = ENV["SLKDOL_ADMIN"]
      end
    else
      @current_user = nil
      cookies.delete('slkdol')
    end
  end

  private
  def require_current_user
    unless current_user?
      redirect_to "/signin"
      return false
    end
    current_user
  end
end
