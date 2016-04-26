class CreateTimeEntries < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      CREATE EXTENSION IF NOT EXISTS citext;

      CREATE TABLE time_entries (
        id citext primary key,  -- employee_id-ccyymmdd
        employee_id citext not null,
        pay_day date,
        day date,
        ssn citext,
        name citext,
        rate decimal(8,2),
        pieces decimal(8,2),
        hours decimal(8,2),
        amount decimal(8,2), -- wage_paid,

        start_time timestamptz,
        end_time timestamptz,
        meal_start_time timestamptz,
        meal_end_time timestamptz,

        flag bool,
        notes citext
      );
      create index time_entries_employee_id_key on time_entries(employee_id);
      create index time_entries_pay_day_key on time_entries(pay_day);
      create index time_entries_day_key on time_entries(day);

      CREATE TABLE time_entries_activities (
        id serial,
        created_at timestamptz not null,
        username citext not null,
        time_entries_id citext not null references time_entries(id) on delete cascade,
        data jsonb
      );
      create index time_entries_activities_username_key on time_entries_activities(username);
      create index time_entries_activities_fkey on time_entries_activities(time_entries_id);

      -- agpay source table, can copy in from csv via:
      -- \copy agpay FROM '/Users/troy/Projects/slkdol/file.csv' DELIMITER ',' CSV
      -- insert into time_entries(id,employee_id,day,ssn,name,rate,pieces,hours,amount)
      -- select
      --   employee_id||'-'||to_char(day,'YYYYMMDD'),
      --   employee_id,
      --   day,ssn,name,
      --   sum(rate),sum(pieces),sum(hours),sum(amount)
      -- from agpay
      -- group by
      --   employee_id||'-'||to_char(day,'YYYYMMDD'),
      --   employee_id,
      --   day,ssn,name;

      CREATE TABLE agpay (
        employee_id citext,
        name citext,
        ssn citext,
        day date,
        class citext,
        unknown1 citext,
        crop citext,
        unknown2 citext,
        task citext,
        type citext,
        ranch citext,
        crew citext,
        rate decimal(8,2),
        pieces decimal(8,2),
        hours decimal(8,2),
        amount decimal(8,2) -- wage_paid,
      );
      create index agpay_key on agpay(employee_id,day);

    SQL
  end

end
