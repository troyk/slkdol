class TimeEntry < ActiveRecord::Base

  validates :day, :employee_id, :name, presence: true

  def self.assign_ranches
    TimeEntry.connection.select_rows("select id,employee_id,day,amount from time_entries where ranch is null").each do |id,employee_id,day,amount|
      ranch = TimeEntry.connection.select_value("select ranch from agpay where employee_id='#{employee_id}' AND day='#{day}' AND amount='#{amount.blank?? '0' : amount}'")
      if ranch.nil?
        ranch = TimeEntry.connection.select_value("select ranch from agpay where employee_id='#{employee_id}' AND day='#{day}' and ranch not in(select te.ranch from time_entries te where te.employee_id='#{employee_id}' AND te.day='#{day}')")
      end
      if ranch.nil?
        ranch = TimeEntry.connection.select_value("select ranch from agpay where employee_id='#{employee_id}' AND day<'#{day}' limit 1")
      end
      TimeEntry.connection.execute "UPDATE time_entries SET ranch='#{ranch}' WHERE id=#{id}"
    end
  end

  # use custom serialization
  def serializable_hash(options = nil)
    h = super(options)
    h.each {|k,v|
      case k
      when "start_time","end_time","meal_start_time","meal_end_time"
        h[k] = v.try(:strftime,"%H:%M")
      end
    }
    h
  end

end
