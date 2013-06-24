class CreateTokopuyos < ActiveRecord::Migration
  def change
    create_table :tokopuyos do |t|

      t.timestamps
    end
  end
end
