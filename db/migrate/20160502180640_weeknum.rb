class Weeknum < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries add column weeknum int;
      update time_entries set weeknum = EXTRACT(WEEK FROM day);
      create index time_entries_week_day_key on time_entries(weeknum,day);
    SQL
  end
end
