class TimeController < ApplicationController
  def index
    edit
  end

  def show
    edit
  end

  def edit
    # 2013: 2012-12-31  2013-12-29
    # 2014: 2013-12-30  2014-12-28
    if !params.key?(:year)
      params[:year] = session[:year]
    end
    if params[:year] == "2013"
      @year_filter_sql = "day >= '2012-12-31' and day <= '2013-12-29'"
    else
      params[:year] = "2014"
      @year_filter_sql = "day >= '2013-12-30' and day <= '2014-12-28'"
    end
    session[:year] = params[:year]
    @weeks = ::TimeEntry.connection.select_all("select weeknum,min(day) as start_day,max(day) as end_day,count(*) FILTER (WHERE audited=false) from time_entries where #{@year_filter_sql} group by weeknum order by weeknum;")
    if params[:id] && params[:id].to_i > 0
      if request.format != "application/json"
        if params.key?(:all)
          @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited,array_agg(time_entries order by day) as entries from time_entries where weeknum=#{params[:id].to_i} and #{@year_filter_sql} group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
        else
          @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited,ARRAY(select subq from time_entries subq where subq.weeknum=#{params[:id].to_i} and subq.employee_id = time_entries.employee_id order by subq.day) as entries from time_entries where weeknum=#{params[:id].to_i} and #{@year_filter_sql} and audited=false group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
        end
      end
      @current_week = @weeks[params[:id].to_i-1]
      # if params.key?(:all)
      #   @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited from time_entries where weeknum=#{params[:id].to_i} and day <'2014-12-29' group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
      # else
      #   @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited from time_entries where weeknum=#{params[:id].to_i} and day <'2014-12-29' and audited=false group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
      # end

    end
    @employees ||= "[]"
    if request.format == "application/json"
      render json: {
        weeks: @weeks,
        employees: @employees,
        currentWeek: @current_week
      }
    else
      render action: :edit
    end
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
    if @te.in_agpay == false
      @te.update!(params.permit(
        :day, :rate, :pieces, :hours, :amount
      ))
    end
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
