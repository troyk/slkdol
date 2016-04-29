class TeSource < ActiveRecord::Migration
  def up
    <<-SQL.split(';').each {|sql| execute sql}
      alter table time_entries add column in_agpay bool not null default true;
    SQL
  end
end
