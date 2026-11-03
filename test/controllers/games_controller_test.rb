require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get games_show_url
    assert_response :success
  end
    test "rejects moves after checkmate" do
    game = Game.create!(fen: "k7/1Q6/2K5/8/8/8/8/8 b - - 0 1")

    post chess_move_path(game), params: { from: "a8", to: "a7" }

    assert_response :unprocessable_entity
        assert_equal "Game is over", JSON.parse(response.body)["error"]
    assert_equal "k7/1Q6/2K5/8/8/8/8/8 b - - 0 1", game.reload.fen
  end

  test "accepts the selected pawn promotion piece" do
    game = Game.create!(fen: "7k/P7/8/8/8/8/8/7K w - - 0 1")

    post chess_move_path(game), params: { from: "a7", to: "a8", promotion: "N" }

    assert_response :success
    assert_equal "N", game.reload.piece_at("a8")
  end

  test "saves captured material after a move" do
    game = Game.create!(fen: "k7/8/8/3q4/3R4/8/8/7K w - - 0 1")

    post chess_move_path(game), params: { from: "d4", to: "d5" }

    assert_response :success
    assert_equal ["q"], game.reload.captured_pieces("w")
    assert_equal 9, game.material_score("w")
  end

  test "human move is saved before the computer responds" do
    game = Game.create!(computer_color: "b")

    post chess_move_path(game), params: { from: "e2", to: "e4" }

    assert_response :success
    assert_equal true, JSON.parse(response.body)["computer_pending"]
    assert_equal "b", game.reload.turn
    assert_equal 8, game.board.flatten.count { |piece| piece == "p" }
  end

  test "computer responds when its delayed move is requested" do
    game = Game.create!(computer_color: "b", computer_difficulty: "hard")
    game.move_piece("e2", "e4")
    game.save!

    post chess_computer_move_path(game)

    assert_response :success
    assert_equal true, JSON.parse(response.body)["computer_moved"]
    assert_equal "w", game.reload.turn
  end

  test "computer does not move in a local game" do
    game = Game.create!

    post chess_computer_move_path(game)

    assert_response :success
    assert_equal false, JSON.parse(response.body)["computer_moved"]
    assert_equal "w", game.reload.turn
  end

  test "computer opens when the player chooses black" do
    assert_difference("Game.count", 1) do
      post new_chess_game_path, params: { computer_color: "w", computer_difficulty: "hard" }
    end

    game = Game.order(:id).last
    assert_redirected_to saved_chess_game_path(game)
    assert_equal "w", game.turn
    assert_equal "w", game.computer_color
    assert_equal "hard", game.computer_difficulty

    post chess_computer_move_path(game)

    assert_response :success
    assert_equal "b", game.reload.turn
  end

  test "board orientation follows the player's color" do
    white_player_game = Game.create!(computer_color: "b")
    get saved_chess_game_path(white_player_game)

    assert_response :success
    assert_select ".chessboard:not(.board-flipped)"

    black_player_game = Game.create!(computer_color: "w")
    get saved_chess_game_path(black_player_game)

    assert_response :success
    assert_select ".chessboard.board-flipped"
  end

  test "lobby offers both player colors against the computer" do
    get root_path

    assert_response :success
    assert_select "button", "Easy · Play White"
    assert_select "button", "Medium · Play White"
    assert_select "button", "Hard · Play White"
    assert_select "button", "Easy · Play Black"
    assert_select "button", "Medium · Play Black"
    assert_select "button", "Hard · Play Black"
    assert_equal [
      "Easy · Play White",
      "Easy · Play Black",
      "Medium · Play White",
      "Medium · Play Black",
      "Hard · Play White",
      "Hard · Play Black"
    ], css_select(".computer-game-options button").map(&:text)
  end

  test "provides a legal move hint" do
    game = Game.create!

    get chess_hint_path(game), headers: { "Accept" => "application/json" }

    assert_response :success
    hint = JSON.parse(response.body).fetch("hint")
    assert_includes game.legal_moves_from(hint.fetch("from")), hint.fetch("to")
  end

  test "shows the checkmate scene with the winner" do
    game = Game.create!(fen: "k7/1Q6/2K5/8/8/8/8/8 b - - 0 1")

    get saved_chess_game_path(game)

    assert_response :success
    assert_select ".checkmate-overlay" do
      assert_select "h2", "Checkmate"
      assert_select ".checkmate-winner", "White wins"
    end
  end
end
