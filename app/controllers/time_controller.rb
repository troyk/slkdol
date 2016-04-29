class TimeController < ApplicationController
  def index
    edit
  end

  def show
    # if params[:paydate]
    #   @days_in_payday = ::TimeEntry.where(pay_day: params[:paydate]).order("day").group("day").pluck(:day)
    #   params[:id] = ::TimeEntry.where(pay_day: params[:paydate]).order("day").limit(1).pluck(:day).first
    # end
    # @entries = ::TimeEntry.where(day: params[:id]).order("name").to_a
    # if @entries.any?
    #   @day = @entries.first.day
    #   @pay_day = @entries.first.pay_day
    # end
    # if !@days_in_payday && @pay_day
    #   @days_in_payday = ::TimeEntry.where(pay_day: @pay_day).order("day").group("day").pluck(:day)
    # end
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



    #   @pay_period = ::PayPeriod.find(params[:id])
    #   @dirty_names, @names = ::TimeEntry.connection.select_all("select id,name,bool_and(audited) as audited from time_entries where pay_period='#{@pay_period.id}' group by id,name;").partition{|t|
    #     t["audited"] != "t"
    #   }
    # else
    #   @pay_period = ::PayPeriod.new
    #   @dirty_names, @names = [], []
    # end
    #
    #
    # @entries ||= []
    # @dirty_pay_periods,@pay_periods = ::PayPeriod.connection.select_all("select id,(select count(*) from time_entries te where te.pay_period=pp.id and te.audited=false) as dirty from pay_periods pp").partition{|pp|
    #     pp["dirty"].to_i > 0
    # }
    # @pay_days = ::TimeEntry.connection.select_all("select pay_day from time_entries group by pay_day order by pay_day")
    # @unassigned_days = ::TimeEntry.connection.select_all("select day from time_entries where pay_day is null group by day order by day")
    render action: :edit
  end

  def update
    @te = ::TimeEntry.where(id: params[:id]).take
    @te.update!(params.permit(
      :start_time,:end_time,:meal_start_time,:meal_end_time,:audited
    ))
    render json: @te.reload
  end

  # time entries are created from payroll.  We use the create method to set the
  # paydate for a range of dates
  def create
    if params[:pay_day] && params[:start_day] && params[:end_day]
      #::TimeEntry.where("day<? OR day>?",params[:start_day],params[:end_day]).update_all(pay_day: nil)
      ::TimeEntry.where("day>=? AND day<=?",params[:start_day],params[:end_day]).update_all(pay_day: params[:pay_day])
    end
    redirect_to "/time/#{params[:start_day]}"
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
      else
        updates[name] = params[name]
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
