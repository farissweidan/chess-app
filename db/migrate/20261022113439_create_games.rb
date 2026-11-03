class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
     t.string :fen, null: false, default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
     t.string :status, null: false, default: "active"

    end
  end
end
