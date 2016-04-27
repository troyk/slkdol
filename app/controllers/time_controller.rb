class TimeController < ApplicationController
  def index
    edit
  end

  def show
    if params[:paydate]
      @days_in_payday = ::TimeEntry.where(pay_day: params[:paydate]).order("day").group("day").pluck(:day)
      params[:id] = ::TimeEntry.where(pay_day: params[:paydate]).order("day").limit(1).pluck(:day).first
    end
    @entries = ::TimeEntry.where(day: params[:id]).order("name").to_a
    if @entries.any?
      @day = @entries.first.day
      @pay_day = @entries.first.pay_day
    end
    if !@days_in_payday && @pay_day
      @days_in_payday = ::TimeEntry.where(pay_day: @pay_day).order("day").group("day").pluck(:day)
    end
    edit
  end

  def edit
    @entries ||= []
    @pay_days = ::TimeEntry.connection.select_all("select pay_day from time_entries group by pay_day order by pay_day")
    @unassigned_days = ::TimeEntry.connection.select_all("select day from time_entries where pay_day is null group by day order by day")
    render action: :edit
  end

  def update
    @te = ::TimeEntry.where(id: params[:id]).take
    if @te.nil?
      update_day
      return
    end
    @te.update!(params.permit(
      :start_time,:end_time,:meal_start_time,:meal_end_time,:audited
    ))
    render json: @te.reload
  end

  def update_day
    updates = {}
    if params.key?(:pay_day)
      updates[:pay_day] = params[:pay_day].strip.blank?? nil : params[:pay_day]
    end
    [:start_time, :end_time,:meal_start_time, :meal_end_time].each do |name|
      next unless params.key?(name)
      if params[name].strip.blank?
        updates[name] = nil
      end
    end
    if updates.any?
      begin
        q = ::TimeEntry.where(day: params[:id])
        unless params.key?(:override)
          updates.each do |k,v|
            q = q.where("#{k} IS NOT NULL")
          end
        end
        q.update_all(updates)
        flash.now[:success] = "day updated overide(#{params.key?(:override)})"
      rescue StandardError => e
        flash.now[:alert] = e.message
      end
    end
    show
  end


end
