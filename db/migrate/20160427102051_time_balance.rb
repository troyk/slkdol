class TimeBalance < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries drop column flag;
      alter table time_entries drop column notes;

      alter table time_entries alter column start_time type time;
      alter table time_entries alter column end_time type time;
      alter table time_entries alter column meal_start_time type time;
      alter table time_entries alter column meal_end_time type time;

      alter table time_entries add column timecard_rate decimal(8,2);
      alter table time_entries add column timecard_pieces decimal(8,2);
      alter table time_entries add column timecard_hours decimal(8,2);
      alter table time_entries add column timecard_amount decimal(8,2);

    SQL

    execute File.read(Rails.root.join('db/fn/time_entries_calc_balance_trig.sql'))

    <<-SQL.split(';').each {|sql| execute sql}
      CREATE TRIGGER time_entries_calc_balance_trig BEFORE INSERT OR UPDATE ON time_entries FOR EACH ROW EXECUTE PROCEDURE time_entries_calc_balance_trig();

      -- invoke the trigger on all the current rows
      UPDATE time_entries set id=id;
    SQL
  end


end
