class TimeController < ApplicationController
  def index
    edit
  end

  def show
    edit
  end

  def edit
    @unaudited_days = ::TimeEntry.connection.select_all("select day,count(*) from time_entries where audited=false group by day order by day")
    if params[:id]
      @pay_day = ::TimeEntry.where(day: params[:id]).where("pay_day IS NOT NULL").limit(1).pluck(:pay_day).first
      if @pay_day
        @start_day, @end_day = *::TimeEntry.connection.select_rows("select min(day),max(day) from time_entries where pay_day='#{@pay_day}'").first
        @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id,max(name) as name,bool_and(audited) as audited,array_agg(time_entries order by day) as entries from time_entries where pay_day='#{@pay_day}' group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
      else
        @start_day, @end_day = params[:id], params[:end_day]
      end
    end
    @employees ||= "[]"
    render action: :edit
  end

  def update
    @te = ::TimeEntry.where(id: params[:id]).take
    if @te.nil? && params[:in_agpay].to_s.downcase[0] == "f"
      @te = ::TimeEntry.new(params.permit(
        :employee_id, :pay_day, :day, :ssn, :name, :rate, :pieces, :hours, :amount
      ))
      @te.in_agpay = false
    end
    @te.update!(params.permit(
      :start_time,:end_time,:meal_start_time,:meal_end_time,:audited
    ))
    render json: @te.reload
  end

  # time entries are created from payroll.  We use the create method to set the
  # paydate for a range of dates
  def create
    if params[:pay_day] && params[:start_day] && params[:end_day]
      ::TimeEntry.where(pay_day: params[:pay_day]).update_all(pay_day: nil)
      ::TimeEntry.where("day>=? AND day<=?",params[:start_day],params[:end_day]).update_all(pay_day: params[:pay_day])
    end
    redirect_to "/time/#{params[:start_day]}"
  end

  def destroy
    @te = ::TimeEntry.where(id: params[:id], in_agpay: false).take
    @te.destroy! unless @te.nil?
    render json: @te
  end

end
