class AddComputerColorToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :computer_color, :string
  end
end
