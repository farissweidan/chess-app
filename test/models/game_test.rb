require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "starting position has eight rows of eight squares" do
    game = Game.new

    assert_equal 8, game.board.length
    assert_equal [8, 8, 8, 8, 8, 8, 8, 8], game.board.map(&:length)
  end
    test "new game starts with white to move" do
    game = Game.new

    assert_equal "w", game.turn
  end
    test "finds pieces on chess squares" do
    game = Game.new

    assert_equal "K", game.piece_at("e1")
    assert_equal "k", game.piece_at("e8")
    assert_nil game.piece_at("e4")
  end

  test "records the piece and points when a queen is captured" do
    game = Game.new(fen: "k7/8/8/3q4/3R4/8/8/7K w - - 0 1")

    assert game.move_piece("d4", "d5")
    assert_equal ["q"], game.captured_pieces("w")
    assert_equal 9, game.material_score("w")
    assert_equal [], game.captured_pieces("b")
    assert_equal 0, game.material_score("b")
  end

  test "easy computer makes a legal move when it is its turn" do
    game = Game.new(computer_color: "b")
    original_board = game.board

    assert game.move_piece("e2", "e4")
    assert game.easy_ai_move!
    assert_equal "w", game.turn
    assert_not_equal original_board, game.board
    assert_equal 8, game.board.flatten.count { |piece| piece == "p" }
  end

  test "easy computer does not move when it is not its turn" do
    game = Game.new(computer_color: "b")

    assert_not game.easy_ai_move!
    assert_equal "w", game.turn
  end

  test "hint suggests a legal move without changing the game" do
    game = Game.new
    original_fen = game.fen

    hint = game.hint_move

    assert_includes game.legal_moves_from(hint.fetch(:from)), hint.fetch(:to)
    assert_equal original_fen, game.fen
  end
    test "white pawn can move forward one square" do
    game = Game.new

    assert_equal ["e3", "e4"], game.pawn_moves_from("e2")
  end
    test "white pawn cannot move forward when blocked" do
    game = Game.new(fen: "4k3/8/8/8/8/4n3/4P3/4K3 w - - 0 1")

    assert_equal [], game.pawn_moves_from("e2")
  end
    test "moving a white pawn updates the board and turn" do
    game = Game.new

    assert game.move_piece("e2", "e4")
    assert_equal "P", game.piece_at("e4")
    assert_nil game.piece_at("e2")
    assert_equal "b", game.turn
  end
    test "white pawn can capture an opposing piece diagonally" do
    game = Game.new(fen: "4k3/8/8/4p3/3P4/8/8/4K3 w - - 0 1")

    assert_equal ["d5", "e5"], game.pawn_moves_from("d4")
  end
    test "white pawn captures a black pawn" do
    game = Game.new(fen: "4k3/8/8/4p3/3P4/8/8/4K3 w - - 0 1")

    assert game.move_piece("d4", "e5")
    assert_equal "P", game.piece_at("e5")
    assert_nil game.piece_at("d4")
    assert_equal "b", game.turn
  end
    test "white knight can jump to its starting moves" do
    game = Game.new

    assert_equal ["a3", "c3"], game.knight_moves_from("b1")
  end
    test "moving a white knight updates the board and turn" do
    game = Game.new

    assert game.move_piece("b1", "a3")
    assert_equal "N", game.piece_at("a3")
    assert_nil game.piece_at("b1")
    assert_equal "b", game.turn
  end
    test "bishop moves diagonally across empty squares" do
    game = Game.new(fen: "k7/8/8/8/3B4/8/8/7K w - - 0 1")

    expected_moves = %w[a1 b2 c3 e3 f2 g1 a7 b6 c5 e5 f6 g7 h8]
    assert_equal expected_moves.sort, game.bishop_moves_from("d4").sort
  end
    test "moving a white bishop updates the board and turn" do
    game = Game.new(fen: "k7/8/8/8/3B4/8/8/7K w - - 0 1")

    assert game.move_piece("d4", "f6")
    assert_equal "B", game.piece_at("f6")
    assert_nil game.piece_at("d4")
    assert_equal "b", game.turn
  end
    test "rook moves horizontally and vertically across empty squares" do
    game = Game.new(fen: "k7/8/8/8/3R4/8/8/7K w - - 0 1")

    expected_moves = %w[a4 b4 c4 e4 f4 g4 h4 d1 d2 d3 d5 d6 d7 d8]
    assert_equal expected_moves.sort, game.rook_moves_from("d4").sort
  end
    test "moving a white rook updates the board and turn" do
    game = Game.new(fen: "k7/8/8/8/3R4/8/8/7K w - - 0 1")

    assert game.move_piece("d4", "d6")
    assert_equal "R", game.piece_at("d6")
    assert_nil game.piece_at("d4")
    assert_equal "b", game.turn
  end
    test "queen moves horizontally, vertically, and diagonally" do
    game = Game.new(fen: "k7/8/8/8/3Q4/8/8/7K w - - 0 1")

    expected_moves = %w[
      a1 b2 c3 e3 f2 g1
      a4 b4 c4 e4 f4 g4 h4
      a7 b6 c5 d1 d2 d3 d5 d6 d7 d8
      e5 f6 g7 h8
    ]

    assert_equal expected_moves.sort, game.queen_moves_from("d4").sort
  end
    test "moving a white queen updates the board and turn" do
    game = Game.new(fen: "k7/8/8/8/3Q4/8/8/7K w - - 0 1")

    assert game.move_piece("d4", "d6")
    assert_equal "Q", game.piece_at("d6")
    assert_nil game.piece_at("d4")
    assert_equal "b", game.turn
  end
    test "king moves one square in any direction" do
    game = Game.new(fen: "k7/8/8/8/4K3/8/8/8 w - - 0 1")

    expected_moves = %w[d3 e3 f3 d4 f4 d5 e5 f5]
    assert_equal expected_moves.sort, game.king_moves_from("e4").sort
  end
    test "moving a white king updates the board and turn" do
    game = Game.new(fen: "k7/8/8/8/4K3/8/8/8 w - - 0 1")

    assert game.move_piece("e4", "f5")
    assert_equal "K", game.piece_at("f5")
    assert_nil game.piece_at("e4")
    assert_equal "b", game.turn
  end
    test "king cannot move onto a square attacked by an enemy rook" do
    game = Game.new(fen: "k4r2/8/8/8/4K3/8/8/8 w - - 0 1")

    assert_not game.move_piece("e4", "f4")
    assert_equal "K", game.piece_at("e4")
    assert_nil game.piece_at("f4")
  end
    test "king cannot move onto a square attacked by other pieces" do
    positions = [
      "k7/8/6n1/8/4K3/8/8/8 w - - 0 1", # knight
            "k7/2b5/8/8/4K3/8/8/8 w - - 0 1", # bishop
      "k4q2/8/8/8/4K3/8/8/8 w - - 0 1", # queen
      "k7/8/8/6p1/4K3/8/8/8 w - - 0 1", # pawn
      "8/8/8/6k1/4K3/8/8/8 w - - 0 1"   # king
    ]

    positions.each do |fen|
      game = Game.new(fen: fen)
      assert_not game.move_piece("e4", "f4"), "Expected f4 to be attacked in #{fen}"
    end
  end

  test "a move cannot capture the opposing king" do
    game = Game.new(fen: "4k3/4R3/8/8/8/8/8/4K3 w - - 0 1")

    assert_not game.move_piece("e7", "e8")
    assert_equal "k", game.piece_at("e8")
  end

    test "a piece cannot move if it exposes its king to check" do
    game = Game.new(fen: "k3r3/8/8/8/8/8/4R3/4K3 w - - 0 1")

    assert_not game.move_piece("e2", "d2")
    assert_equal "R", game.piece_at("e2")
    assert_nil game.piece_at("d2")
  end
    test "a piece can move to block check against its king" do
    game = Game.new(fen: "k3r3/8/8/8/8/8/R7/4K3 w - - 0 1")

    assert game.move_piece("a2", "e2")
    assert_equal "R", game.piece_at("e2")
    assert_equal "b", game.turn
  end
    test "detects checkmate" do
    game = Game.new(fen: "k7/1Q6/2K5/8/8/8/8/8 b - - 0 1")

    assert game.checkmate?
  end
    test "reports when the player to move is in check" do
    game = Game.new(fen: "k7/1Q6/2K5/8/8/8/8/8 b - - 0 1")

    assert game.in_check?
  end
    test "detects stalemate" do
    game = Game.new(fen: "k7/8/1QK5/8/8/8/8/8 b - - 0 1")

    assert_not game.in_check?
    assert game.stalemate?
  end
    test "white can castle kingside and the rook moves too" do
    game = Game.new(fen: "4k3/8/8/8/8/8/8/4K2R w K - 0 1")

    assert game.move_piece("e1", "g1")
    assert_equal "K", game.piece_at("g1")
    assert_equal "R", game.piece_at("f1")
    assert_nil game.piece_at("e1")
    assert_nil game.piece_at("h1")
  end
    test "moving the king removes its castling rights" do
    game = Game.new(fen: "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")

    assert game.move_piece("e1", "e2")
    assert_equal "-", game.fen.split[2]
  end
    test "white captures a pawn en passant" do
    game = Game.new(fen: "k7/8/8/3pP3/8/8/8/7K w - d6 0 1")

    assert game.move_piece("e5", "d6")
    assert_equal "P", game.piece_at("d6")
    assert_nil game.piece_at("e5")
    assert_nil game.piece_at("d5")
    assert_equal ["p"], game.captured_pieces("w")
    assert_equal 1, game.material_score("w")
  end
    test "white pawn promotes to a queen on the last rank" do
    game = Game.new(fen: "7k/P7/8/8/8/8/8/7K w - - 0 1")

    assert game.move_piece("a7", "a8")
    assert_equal "Q", game.piece_at("a8")
    assert_nil game.piece_at("a7")
  end

  test "white pawn can promote to a rook bishop or knight" do
    { "R" => "R", "B" => "B", "N" => "N" }.each do |promotion, expected_piece|
      game = Game.new(fen: "7k/P7/8/8/8/8/8/7K w - - 0 1")

      assert game.move_piece("a7", "a8", promotion)
      assert_equal expected_piece, game.piece_at("a8")
    end
  end

  test "black pawn can promote to a chosen piece" do
    game = Game.new(fen: "7k/8/8/8/8/8/p7/7K b - - 0 1")

    assert game.move_piece("a2", "a1", "N")
    assert_equal "n", game.piece_at("a1")
  end

  test "pawn promotion rejects unsupported pieces" do
    game = Game.new(fen: "7k/P7/8/8/8/8/8/7K w - - 0 1")

    assert_not game.move_piece("a7", "a8", "K")
    assert_equal "P", game.piece_at("a7")
  end
    test "medium computer prefers capturing a queen" do
    game = Game.new(
      computer_color: "b",
      fen: "k2r4/8/8/8/3Q4/8/8/7K b - - 0 1"
    )

    assert game.medium_ai_move!
    assert_equal ["Q"], game.captured_pieces("b")
    assert_equal 9, game.material_score("b")
  end

  test "medium computer makes a legal move when there are no captures" do
    game = Game.new(computer_color: "b")

    assert game.move_piece("e2", "e4")
    assert game.medium_ai_move!
    assert_equal "w", game.turn
  end

  test "hard computer chooses a safe queen capture after looking ahead" do
    game = Game.new(
      computer_color: "b",
      computer_difficulty: "hard",
      fen: "k2r4/8/8/8/3Q4/8/8/7K b - - 0 1"
    )

    assert game.computer_move!
    assert_equal ["Q"], game.captured_pieces("b")
    assert_equal 9, game.material_score("b")
    assert_equal "w", game.turn
  end

  test "hard computer chooses checkmate over a material advantage" do
    game = Game.new(
      computer_color: "b",
      computer_difficulty: "hard",
      fen: "8/8/8/8/8/5k2/q7/7K b - - 0 1"
    )

    assert game.computer_move!
    assert game.checkmate?
    assert_equal "q", game.piece_at("g2")
  end

  test "hard computer does not move when it is not its turn" do
    game = Game.new(computer_color: "b", computer_difficulty: "hard")

    assert_not game.hard_ai_move!
    assert_equal "w", game.turn
  end
end
