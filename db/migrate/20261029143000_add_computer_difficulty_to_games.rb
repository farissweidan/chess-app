class AddComputerDifficultyToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :computer_difficulty, :string, default: "easy", null: false
  end
end
