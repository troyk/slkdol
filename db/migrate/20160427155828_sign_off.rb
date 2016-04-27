class SignOff < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries add column audited bool;
    SQL
    execute File.read(Rails.root.join('db/fn/time_entries_calc_balance_trig.sql'))
  end
end
