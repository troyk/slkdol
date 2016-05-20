class TimeController < ApplicationController
  PAY_YEARS = {
    "2013" => "day >= '2012-12-31' and day <= '2013-12-29'",
    "2014" => "day >= '2013-12-30' and day <= '2014-12-28'"
  }
  def index
    edit
  end

  def show
    edit
  end

  def edit
    # 2013: 2012-12-31  2013-12-29
    # 2014: 2013-12-30  2014-12-28
    # default to 2014 for now
    params[:year] = "2014" unless params[:year] == "2013"
    @year_filter_sql = PAY_YEARS[params[:year]]
    @weeks = ::TimeEntry.connection.select_all("select weeknum,min(day) as start_day,max(day) as end_day,count(*) FILTER (WHERE audited=false) from time_entries where #{@year_filter_sql} group by weeknum order by weeknum;")
    if params[:id] && params[:id].to_i > 0
      if request.format != "application/json"
        if params.key?(:all)
          @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited,array_agg(time_entries order by day) as entries from time_entries where weeknum=#{params[:id].to_i} and #{@year_filter_sql} group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
        else
          @employees = "["+::TimeEntry.connection.select_rows("select to_json(r) from (select employee_id as id,max(name) as name,bool_and(audited) as audited,ARRAY(select subq from time_entries subq where subq.weeknum=#{params[:id].to_i} and subq.employee_id = time_entries.employee_id and #{@year_filter_sql} order by subq.day) as entries from time_entries where weeknum=#{params[:id].to_i} and #{@year_filter_sql} and audited=false group by employee_id order by max(name))r;").join(",").gsub(/\d{2}:\d{2}\K:\d{2}/, '')+"]"
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


  # paydate editing
  def paydates
    # if request.post?
    #   PAY_YEARS.each do |yr,day_filter|
    #     next unless params[yr].is_a?(Hash)
    #      params[yr].each do |weeknum,day|
    #        next if day.blank?
    #        next if params["#{yr}#{weeknum}"] == day
    #        ::TimeEntry.where(weeknum: weeknum).where(day_filter).update_all(pay_day: day)
    #      end
    #   end
    # end
    PAY_YEARS.each do |yr,day_filter|
      rows = TimeEntry.connection.select_all("select weeknum,max(day) from time_entries where pay_day is null and #{day_filter} and weeknum is not null group by weeknum").to_a
      rows.each do |row|
         TimeEntry.connection.execute <<-SQL
           update time_entries set
             pay_day = (select generate_series FROM generate_series('#{row["max"]}'::timestamp,'#{row["max"]}'::timestamp+'1 week','1 day'::interval) where EXTRACT(DOW FROM generate_series)=5 and EXTRACT(WEEK FROM '#{row["max"]}'::timestamp)<EXTRACT(WEEK FROM generate_series))
           where weeknum=#{row["weeknum"]} and #{day_filter}
         SQL
      end
    end
    @dates = Hash[PAY_YEARS.map{|yr,day_filter| [yr, ::TimeEntry.connection.select_all("select weeknum, min(pay_day) as pay_date from time_entries where #{day_filter} group by weeknum order by weeknum")] } ]
  end

end
