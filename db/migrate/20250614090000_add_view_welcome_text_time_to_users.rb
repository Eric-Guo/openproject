# frozen_string_literal: true

class AddViewWelcomeTextTimeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :view_welcome_text_time, :datetime
  end
end
