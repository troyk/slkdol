class Ranch < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries add column ranch citext;
    SQL

    ::TimeEntry.assign_ranches
  end
end
