-- calcs if the time card is in balance with the timecard and sets NEW.timecard_amount
-- ONLY RUN BEFORE INSERT/UPDATE
CREATE OR REPLACE FUNCTION time_entries_calc_balance_trig() RETURNS "trigger" AS
$$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    NEW.timecard_hours = EXTRACT(epoch from ((NEW.end_time-NEW.start_time)-(NEW.meal_end_time-NEW.meal_start_time))/3600);
    NEW.timecard_amount = NEW.rate * NEW.timecard_hours;
    IF NEW.timecard_hours = NEW.hours AND NEW.timecard_amount = NEW.amount THEN
      NEW.audited = true;
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE 'plpgsql' VOLATILE;
