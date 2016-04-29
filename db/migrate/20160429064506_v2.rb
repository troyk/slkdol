class V2 < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries rename to old_time_entries;
      drop index time_entries_employee_id_key;
      drop index time_entries_pay_day_key;
      drop index time_entries_day_key;

      CREATE TABLE time_entries (
        id serial primary key,
        employee_id citext not null,
        pay_day date,
        day date,
        ssn citext,
        name citext,
        rate decimal(8,2),
        pieces decimal(8,2),
        hours decimal(8,2),
        amount decimal(8,2), -- wage_paid,

        timecard_rate decimal(8,2),
        timecard_pieces decimal(8,2),
        timecard_hours decimal(8,2),
        timecard_amount decimal(8,2),

        start_time time,
        end_time time,
        meal_start_time time,
        meal_end_time time,

        audited bool not null default false
      );
      create index time_entries_employee_id_key on time_entries(employee_id);
      create index time_entries_pay_day_key on time_entries(pay_day);
      create index time_entries_day_key on time_entries(day);
      CREATE TRIGGER time_entries_calc_balance_trig BEFORE INSERT OR UPDATE ON time_entries FOR EACH ROW EXECUTE PROCEDURE time_entries_calc_balance_trig();
    SQL
    execute File.read(Rails.root.join('db/fn/time_entries_calc_balance_trig.sql'))

    # run the following in psql
    # truncate table agpay;
    # agpay source table, can copy in from csv via:
    # \copy agpay FROM '/Users/troy/Projects/slkdol/file.csv' DELIMITER ',' CSV
    # insert into time_entries(employee_id,day,ssn,name,rate,pieces,hours,amount) select employee_id,day,ssn,name,rate,pieces,hours,amount from agpay;
    #

  end
end
