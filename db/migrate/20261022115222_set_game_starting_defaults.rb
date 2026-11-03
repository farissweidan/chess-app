class SetGameStartingDefaults < ActiveRecord::Migration[8.1]
  def change
    change_column_default :games, :fen, from: nil, to: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    change_column_default :games, :status, from: nil, to: "active"
  end
end
