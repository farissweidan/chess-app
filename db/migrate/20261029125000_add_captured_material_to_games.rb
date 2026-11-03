class AddCapturedMaterialToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :white_captured_pieces, :string, default: "", null: false
    add_column :games, :black_captured_pieces, :string, default: "", null: false
  end
end
