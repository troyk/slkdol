class TimeEntry < ActiveRecord::Base

  validates :day, :employee_id, :name, presence: true

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
