class GamesController < ApplicationController
    def show
    @game = params[:id] ? Game.find(params[:id]) : Game.first_or_create!
  end
    def create
      computer_color = params[:computer_color].presence
      computer_difficulty = %w[easy medium hard].include?(params[:computer_difficulty]) ?
        params[:computer_difficulty] : "easy"
      game = Game.create!(
        computer_color: computer_color,
        computer_difficulty: computer_difficulty
      )
      game.save!
      redirect_to saved_chess_game_path(game)
    end

    def reset
      game = Game.find(params[:id])
    game.update!(
      fen: Game.new.fen,
      status: "active",
      white_captured_pieces: "",
      black_captured_pieces: "",
      computer_color: game.computer_color,
      computer_difficulty: game.computer_difficulty
    )
    game.save!
    redirect_to saved_chess_game_path(game)
  end

      def move
    game = Game.find(params[:id])
        if game.checkmate? || game.stalemate?
      render json: { error: "Game is over" }, status: :unprocessable_entity
      return
    end
    move_params = params.permit(:from, :to, :promotion)
    from = move_params[:from].to_s
    to = move_params[:to].to_s

    unless from.match?(/\A[a-h][1-8]\z/) && to.match?(/\A[a-h][1-8]\z/)
      render json: { error: "Invalid square" }, status: :unprocessable_entity
      return
    end

    unless game.move_piece(from, to, move_params[:promotion])
      render json: { error: "Illegal move" }, status: :unprocessable_entity
      return
    end

    computer_pending = game.computer_color == game.turn &&
      !game.checkmate? &&
      !game.stalemate?
    game.save!
    render json: { board: game.board, turn: game.turn, computer_pending: computer_pending }
  end

  def computer_move
    game = Game.find(params[:id])

    if game.computer_color == game.turn && !game.checkmate? && !game.stalemate?
      game.computer_move!
      game.save!
      render json: { board: game.board, turn: game.turn, computer_moved: true }
    else
      render json: { board: game.board, turn: game.turn, computer_moved: false }
    end
  end

  def hint
    game = Game.find(params[:id])

    if game.computer_color == game.turn || game.checkmate? || game.stalemate?
      render json: { error: "A hint is not available right now" }, status: :unprocessable_entity
      return
    end

    suggestion = game.hint_move
    if suggestion
      render json: { hint: suggestion }
    else
      render json: { error: "No legal moves are available" }, status: :unprocessable_entity
    end
  end

    def index
    @game = Game.order(updated_at: :desc).first
  end
    def legal_moves
    game = Game.find(params[:id])
    square = params[:from].to_s

    unless square.match?(/\A[a-h][1-8]\z/)
      render json: { error: "Invalid square" }, status: :unprocessable_entity
      return
    end

    render json: { moves: game.legal_moves_from(square) }
  end
end
