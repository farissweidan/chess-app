class EnforceGameDefaults < ActiveRecord::Migration[8.1]
  STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  def change
    change_column_default :games, :fen, from: nil, to: STARTING_FEN
    change_column_default :games, :status, from: nil, to: "active"
    change_column_null :games, :fen, false, STARTING_FEN
    change_column_null :games, :status, false, "active"
  end
end
