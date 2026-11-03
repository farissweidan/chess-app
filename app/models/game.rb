class Game < ApplicationRecord
  def board
    fen.split.first.split("/").map do |rank|
      rank.chars.flat_map do |square|
        square.match?(/\d/) ? Array.new(square.to_i) : [square]
      end
    end
  end
    def turn
    fen.split[1]
  end
    def piece_at(square)
    file = square[0].ord - "a".ord
    rank = square[1].to_i

    board[8 - rank][file]
  end

    def captured_pieces(color)
      (color == "w" ? white_captured_pieces : black_captured_pieces).chars
    end

    def material_score(color)
      values = { "P" => 1, "N" => 3, "B" => 3, "R" => 5, "Q" => 9 }
      captured_pieces(color).sum { |piece| values.fetch(piece.upcase, 0) }
    end

    def hint_move
      candidates = []

      board.each_with_index do |row, row_index|
        row.each_with_index do |piece, file_index|
          next unless piece

          piece_color = piece == piece.upcase ? "w" : "b"
          next unless piece_color == turn

          from = "#{(file_index + "a".ord).chr}#{8 - row_index}"
          legal_moves_from(from).each do |to|
            candidate = self.class.new(fen: fen)
            candidates << { from: from, to: to } if candidate.move_piece(from, to, record_capture: false)
          end
        end
      end

      candidates.sample
    end

    def easy_ai_move!
      return false unless computer_color == turn

      candidates = legal_ai_candidates
      return false if candidates.empty?

      move = candidates.sample
      move_piece(move[:from], move[:to])
    end

    def medium_ai_move!
      return false unless computer_color == turn

      candidates = legal_ai_candidates
      return false if candidates.empty?

      best_capture_value = candidates.map { |candidate| candidate[:capture_value] }.max
      move = candidates
        .select { |candidate| candidate[:capture_value] == best_capture_value }
        .sample

      move_piece(move[:from], move[:to])
    end

    def hard_ai_move!
      return false unless computer_color == turn

      candidates = ordered_ai_moves
      return false if candidates.empty?

      best_score = -Float::INFINITY
      alpha = -Float::INFINITY
      best_move = candidates.first
      candidates.each do |move|
        score = -position_after_ai_move(move).search_ai_position(2, -Float::INFINITY, -alpha, 1)
        if score > best_score
          best_score = score
          best_move = move
        end
        alpha = score if score > alpha
      end

      move_piece(best_move[:from], best_move[:to])
    end

    def computer_move!
      case computer_difficulty
      when "hard"
        hard_ai_move!
      when "medium"
        medium_ai_move!
      else
        easy_ai_move!
      end
    end

    def legal_ai_moves
      legal_ai_candidates
    end

        def pawn_moves_from(square)
      pawn = piece_at(square)
      return [] unless ["P", "p"].include?(pawn)

      file = square[0]
      rank = square[1].to_i
      direction = pawn == "P" ? 1 : -1
    starting_rank = pawn == "P" ? 2 : 7
    next_rank = rank + direction
    moves = []

    if (1..8).cover?(next_rank) && piece_at("#{file}#{next_rank}").nil?
      moves << "#{file}#{next_rank}"

      double_step_rank = rank + (direction * 2)
      if rank == starting_rank && piece_at("#{file}#{double_step_rank}").nil?
        moves << "#{file}#{double_step_rank}"
      end
    end
        [-1, 1].each do |file_offset|
      capture_file = file.ord + file_offset
      next unless ("a".ord.."h".ord).cover?(capture_file)

      capture_square = "#{capture_file.chr}#{next_rank}"
      target = piece_at(capture_square)

      opposing_piece = target &&
        ((pawn == "P" && target == target.downcase) ||
         (pawn == "p" && target == target.upcase))

      moves << capture_square if opposing_piece
    end

    en_passant_target = fen.split[3]
    if en_passant_target && en_passant_target[1].to_i == next_rank
      adjacent_file = en_passant_target[0]
      if (adjacent_file.ord - file.ord).abs == 1 &&
         piece_at("#{adjacent_file}#{rank}") == (pawn == "P" ? "p" : "P")
        moves << en_passant_target
      end
    end

    moves
  end
  def knight_moves_from(square)
    knight = piece_at(square)
    return [] unless ["N", "n"].include?(knight)

    file = square[0].ord - "a".ord
    rank = square[1].to_i
    offsets = [
      [-1, 2], [1, 2], [-2, 1], [2, 1],
      [-2, -1], [2, -1], [-1, -2], [1, -2]
    ]

    offsets.filter_map do |file_offset, rank_offset|
      target_file = file + file_offset
      target_rank = rank + rank_offset
      next unless (0..7).cover?(target_file) && (1..8).cover?(target_rank)

      target_square = "#{(target_file + "a".ord).chr}#{target_rank}"
      target_piece = piece_at(target_square)
      own_piece = target_piece &&
        ((knight == "N" && target_piece == target_piece.upcase) ||
         (knight == "n" && target_piece == target_piece.downcase))

      target_square unless own_piece
    end
  end

  def bishop_moves_from(square)
    bishop = piece_at(square)
    return [] unless ["B", "b"].include?(bishop)

    file = square[0].ord - "a".ord
    rank = square[1].to_i
    directions = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
    moves = []

    directions.each do |file_direction, rank_direction|
      target_file = file + file_direction
      target_rank = rank + rank_direction

      while (0..7).cover?(target_file) && (1..8).cover?(target_rank)
        target_square = "#{(target_file + "a".ord).chr}#{target_rank}"
        target_piece = piece_at(target_square)

        if target_piece.nil?
          moves << target_square
        else
          own_piece = (bishop == "B" && target_piece == target_piece.upcase) ||
                      (bishop == "b" && target_piece == target_piece.downcase)
          moves << target_square unless own_piece
          break
        end

        target_file += file_direction
        target_rank += rank_direction
      end
    end

    moves
  end
    def rook_moves_from(square)
    rook = piece_at(square)
    return [] unless ["R", "r"].include?(rook)

    file = square[0].ord - "a".ord
    rank = square[1].to_i
    directions = [[1, 0], [-1, 0], [0, 1], [0, -1]]
    moves = []

    directions.each do |file_direction, rank_direction|
      target_file = file + file_direction
      target_rank = rank + rank_direction

      while (0..7).cover?(target_file) && (1..8).cover?(target_rank)
        target_square = "#{(target_file + "a".ord).chr}#{target_rank}"
        target_piece = piece_at(target_square)

        if target_piece.nil?
          moves << target_square
        else
          own_piece = (rook == "R" && target_piece == target_piece.upcase) ||
                      (rook == "r" && target_piece == target_piece.downcase)
          moves << target_square unless own_piece
          break
        end

        target_file += file_direction
        target_rank += rank_direction
      end
    end

    moves
  end
    def king_moves_from(square)
    king = piece_at(square)
    return [] unless ["K", "k"].include?(king)

    file = square[0].ord - "a".ord
    rank = square[1].to_i

    moves = []

    (-1..1).each do |file_offset|
      (-1..1).each do |rank_offset|
        next if file_offset.zero? && rank_offset.zero?

        target_file = file + file_offset
        target_rank = rank + rank_offset
        next unless (0..7).cover?(target_file) && (1..8).cover?(target_rank)

        target_square = "#{(target_file + "a".ord).chr}#{target_rank}"
        target_piece = piece_at(target_square)

        own_piece = target_piece &&
          ((king == "K" && target_piece == target_piece.upcase) ||
           (king == "k" && target_piece == target_piece.downcase))

        moves << target_square unless own_piece
      end
    end

    moves.concat(castling_moves_from(square))
    moves
  end
    def queen_moves_from(square)
    queen = piece_at(square)
    return [] unless ["Q", "q"].include?(queen)

    file = square[0].ord - "a".ord
    rank = square[1].to_i
    directions = [
      [1, 0], [-1, 0], [0, 1], [0, -1],
      [1, 1], [1, -1], [-1, 1], [-1, -1]
    ]
    moves = []

    directions.each do |file_direction, rank_direction|
      target_file = file + file_direction
      target_rank = rank + rank_direction

      while (0..7).cover?(target_file) && (1..8).cover?(target_rank)
        target_square = "#{(target_file + "a".ord).chr}#{target_rank}"
        target_piece = piece_at(target_square)

        if target_piece.nil?
          moves << target_square
        else
          own_piece = (queen == "Q" && target_piece == target_piece.upcase) ||
                      (queen == "q" && target_piece == target_piece.downcase)
          moves << target_square unless own_piece
          break
        end

        target_file += file_direction
        target_rank += rank_direction
      end
    end

    moves
  end

  def legal_moves_from(square)
    piece = piece_at(square)
    return [] unless piece

    correct_turn = (turn == "w" && piece == piece.upcase) ||
                   (turn == "b" && piece == piece.downcase)
    return [] unless correct_turn

    case piece.upcase
    when "P"
      pawn_moves_from(square)
    when "N"
      knight_moves_from(square)
          when "B"
      bishop_moves_from(square)
          when "R"
      rook_moves_from(square)
          when "Q"
      queen_moves_from(square)
          when "K"
      king_moves_from(square)
    else
      []
    end

  end

    def move_piece(from, to, promotion = "Q", record_capture: true)
       piece = piece_at(from)
    return false unless piece

    correct_turn = (turn == "w" && piece == piece.upcase) ||
                   (turn == "b" && piece == piece.downcase)
    return false unless correct_turn

    legal_moves = case piece.upcase
    when "P"
      pawn_moves_from(from)
    when "N"
      knight_moves_from(from)
          when "B"
      bishop_moves_from(from)
          when "R"
      rook_moves_from(from)
          when "Q"
      queen_moves_from(from)
          when "K"
      king_moves_from(from)
    else
      []

    end

        return false unless legal_moves.include?(to)
        promotes = (piece == "P" && to[1] == "8") || (piece == "p" && to[1] == "1")
        promotion_piece = (promotion || "Q").to_s.upcase
        return false if promotes && !%w[Q R B N].include?(promotion_piece)

        original_fen = fen
    captured_piece = piece_at(to)
        return false if captured_piece&.upcase == "K"

        en_passant_target = fen.split[3]
        if piece.upcase == "P" && to == en_passant_target && captured_piece.nil?
          captured_piece = piece_at("#{to[0]}#{from[1]}")
        end

        position = board
    position[8 - to[1].to_i][to[0].ord - "a".ord] = piece
    position[8 - from[1].to_i][from[0].ord - "a".ord] = nil
    if piece == "P" && to[1] == "8"
      position[0][to[0].ord - "a".ord] = promotion_piece
    elsif piece == "p" && to[1] == "1"
      position[7][to[0].ord - "a".ord] = promotion_piece.downcase
    end

    if piece.upcase == "P" && to == en_passant_target
      position[8 - from[1].to_i][to[0].ord - "a".ord] = nil
    end

    if piece == "K" && from == "e1" && to == "g1"
      position[7][5] = "R"
      position[7][7] = nil
    elsif piece == "K" && from == "e1" && to == "c1"
      position[7][3] = "R"
      position[7][0] = nil
    elsif piece == "k" && from == "e8" && to == "g8"
      position[0][5] = "r"
      position[0][7] = nil
    elsif piece == "k" && from == "e8" && to == "c8"
      position[0][3] = "r"
      position[0][0] = nil
    end

    fields = fen.split
    fields[0] = encode_board(position)
    fields[1] = turn == "w" ? "b" : "w"
        rights = fields[2]

    rights = rights.delete("KQ") if piece == "K"
    rights = rights.delete("kq") if piece == "k"
    rights = rights.delete("K") if piece == "R" && from == "h1"
    rights = rights.delete("Q") if piece == "R" && from == "a1"
    rights = rights.delete("k") if piece == "r" && from == "h8"
    rights = rights.delete("q") if piece == "r" && from == "a8"

    rights = rights.delete("K") if captured_piece == "R" && to == "h1"
    rights = rights.delete("Q") if captured_piece == "R" && to == "a1"
    rights = rights.delete("k") if captured_piece == "r" && to == "h8"
    rights = rights.delete("q") if captured_piece == "r" && to == "a8"

    fields[2] = rights.empty? ? "-" : rights

    fields[3] = if piece == "P" && from[1] == "2" && to[1] == "4"
      "#{from[0]}3"
    elsif piece == "p" && from[1] == "7" && to[1] == "5"
      "#{from[0]}6"
    else
      "-"
    end

    self.fen = fields.join(" ")

        if king_in_check?(original_fen.split[1])
      self.fen = original_fen
      return false
    end

        if record_capture && captured_piece
          capture_attribute = original_fen.split[1] == "w" ? :white_captured_pieces : :black_captured_pieces
          self[capture_attribute] = public_send(capture_attribute) + captured_piece
        end

        true
  end
    def in_check?
    king_in_check?(turn)
  end
    def checkmate?
    color = turn
    return false unless king_in_check?(color)

    original_fen = fen

    board.each_with_index do |row, row_index|
      row.each_with_index do |piece, file_index|
        next unless piece

        piece_color = piece == piece.upcase ? "w" : "b"
        next unless piece_color == color

        from = "#{(file_index + "a".ord).chr}#{8 - row_index}"

        legal_moves_from(from).each do |to|
          if move_piece(from, to, record_capture: false)
            self.fen = original_fen
            return false
          end
        end
      end
    end

    true
  end
    def stalemate?
    return false if in_check?

    color = turn
    original_fen = fen

    board.each_with_index do |row, row_index|
      row.each_with_index do |piece, file_index|
        next unless piece

        piece_color = piece == piece.upcase ? "w" : "b"
        next unless piece_color == color

        from = "#{(file_index + "a".ord).chr}#{8 - row_index}"

        legal_moves_from(from).each do |to|
          if move_piece(from, to, record_capture: false)
            self.fen = original_fen
            return false
          end
        end
      end
    end

    true
  end

  private
    def castling_moves_from(square)
    king = piece_at(square)
    color = king == "K" ? "w" : "b"
    rank = color == "w" ? "1" : "8"
    return [] unless square == "e#{rank}"

    rights = fen.split[2]
    enemy_color = color == "w" ? "b" : "w"
    return [] if king_in_check?(color)

    moves = []

    {
      "K" => { rook: "h", empty: %w[f g], safe: %w[f g], destination: "g" },
      "Q" => { rook: "a", empty: %w[b c d], safe: %w[d c], destination: "c" }
    }.each do |side, details|
      right = color == "w" ? side : side.downcase
      next unless rights.include?(right)
      next unless piece_at("#{details[:rook]}#{rank}") == (color == "w" ? "R" : "r")
      next unless details[:empty].all? { |file| piece_at("#{file}#{rank}").nil? }
      next if details[:safe].any? { |file| square_attacked_by?("#{file}#{rank}", enemy_color) }

      moves << "#{details[:destination]}#{rank}"
    end

    moves
  end
    def legal_ai_candidates
      values = { "P" => 1, "N" => 3, "B" => 3, "R" => 5, "Q" => 9 }
      candidates = []
      en_passant_target = fen.split[3]

      board.each_with_index do |row, row_index|
        row.each_with_index do |piece, file_index|
          next unless piece
          next unless (piece == piece.upcase ? "w" : "b") == turn

          from = "#{(file_index + "a".ord).chr}#{8 - row_index}"
          legal_moves_from(from).each do |to|
            captured_piece = piece_at(to)
            if piece.upcase == "P" && to == en_passant_target && captured_piece.nil?
              captured_piece = piece_at("#{to[0]}#{from[1]}")
            end

            candidate_game = self.class.new(fen: fen)
            next unless candidate_game.move_piece(from, to, record_capture: false)

            candidates << {
              from: from,
              to: to,
              capture_value: captured_piece ? values.fetch(captured_piece.upcase, 0) : 0,
              position: candidate_game
            }
          end
        end
      end

      candidates
    end

    def ordered_ai_moves
      legal_ai_candidates.sort_by { |candidate| candidate[:position].evaluate_ai_position }
    end

    def position_after_ai_move(move)
      move[:position]
    end

    def search_ai_position(depth, alpha, beta, ply)
      return quiescence_ai_position(alpha, beta, ply, 3) if depth.zero?

      moves = ordered_ai_moves
      if moves.empty?
        return in_check? ? -100_000 + ply : 0
      end

      best_score = -Float::INFINITY
      moves.each do |move|
        position = position_after_ai_move(move)
        score = -position.search_ai_position(depth - 1, -beta, -alpha, ply + 1)
        best_score = score if score > best_score
        alpha = score if score > alpha
        break if alpha >= beta
      end

      best_score
    end
    protected :search_ai_position

    def quiescence_ai_position(alpha, beta, ply, depth)
      in_check = in_check?
      stand_pat = evaluate_ai_position

      unless in_check
        return beta if stand_pat >= beta
        alpha = stand_pat if stand_pat > alpha
        return stand_pat if depth.zero?
      end

      moves = in_check ? ordered_ai_moves : ordered_ai_captures
      return in_check ? -100_000 + ply : stand_pat if moves.empty?
      return stand_pat if depth.zero?

      best_score = in_check ? -Float::INFINITY : stand_pat
      moves.each do |move|
        position = position_after_ai_move(move)
        score = -position.quiescence_ai_position(-beta, -alpha, ply + 1, depth - 1)
        best_score = score if score > best_score
        alpha = score if score > alpha
        break if alpha >= beta
      end

      best_score
    end
    protected :quiescence_ai_position

    def ordered_ai_captures
      values = { "P" => 1, "N" => 3, "B" => 3, "R" => 5, "Q" => 9 }
      en_passant_target = fen.split[3]
      candidates = []

      board.each_with_index do |row, row_index|
        row.each_with_index do |piece, file_index|
          next unless piece && (piece == piece.upcase ? "w" : "b") == turn

          from = "#{(file_index + "a".ord).chr}#{8 - row_index}"
          legal_moves_from(from).each do |to|
            captured_piece = piece_at(to)
            if piece.upcase == "P" && to == en_passant_target && captured_piece.nil?
              captured_piece = piece_at("#{to[0]}#{from[1]}")
            end
            next unless captured_piece

            position = self.class.new(fen: fen)
            next unless position.move_piece(from, to, record_capture: false)

            candidates << {
              from: from,
              to: to,
              capture_value: values.fetch(captured_piece.upcase, 0),
              position: position
            }
          end
        end
      end

      candidates.sort_by { |candidate| candidate[:position].evaluate_ai_position }
    end

    def evaluate_ai_position
      piece_values = { "P" => 100, "N" => 320, "B" => 330, "R" => 500, "Q" => 900, "K" => 0 }
      white_score = 0
      bishops = { "w" => 0, "b" => 0 }

      board.each_with_index do |row, row_index|
        row.each_with_index do |piece, file_index|
          next unless piece

          color = piece == piece.upcase ? "w" : "b"
          rank = 8 - row_index
          advancement = color == "w" ? rank - 1 : 8 - rank
          center_distance = (file_index - 3.5).abs + (rank - 4.5).abs
          value = piece_values.fetch(piece.upcase)

          case piece.upcase
          when "P"
            value += advancement * 8
            value += 10 if (1..6).cover?(file_index) && (3..6).cover?(rank)
          when "N"
            value += (7 - center_distance).round * 9
          when "B"
            value += (7 - center_distance).round * 5
            bishops[color] += 1
          when "R"
            value += 18 if (color == "w" && rank == 7) || (color == "b" && rank == 2)
          when "Q"
            value += (7 - center_distance).round * 2
          when "K"
            value += 12 if (color == "w" && rank == 1) || (color == "b" && rank == 8)
          end

          white_score += color == "w" ? value : -value
        end
      end

      white_score += 30 if bishops["w"] >= 2
      white_score -= 30 if bishops["b"] >= 2
      turn == "w" ? white_score : -white_score
    end
    protected :evaluate_ai_position

    def king_in_check?(color)
    king = color == "w" ? "K" : "k"
    king_index = board.flatten.index(king)
    return false unless king_index

    row_index, file_index = king_index.divmod(8)
    king_square = "#{(file_index + "a".ord).chr}#{8 - row_index}"
    attacking_color = color == "w" ? "b" : "w"

    square_attacked_by?(king_square, attacking_color)
  end
      def square_attacked_by?(square, color)
    target_file = square[0].ord - "a".ord
    target_rank = square[1].to_i

    board.each_with_index.any? do |row, row_index|
      row.each_with_index.any? do |piece, file_index|
        next false unless piece

        piece_color = piece == piece.upcase ? "w" : "b"
        next false unless piece_color == color

        from = "#{(file_index + "a".ord).chr}#{8 - row_index}"

        case piece.upcase
        when "P"
          direction = color == "w" ? 1 : -1
          target_rank == 8 - row_index + direction &&
            (target_file - file_index).abs == 1
        when "N"
          knight_moves_from(from).include?(square)
        when "B"
          bishop_moves_from(from).include?(square)
        when "R"
          rook_moves_from(from).include?(square)
        when "Q"
          queen_moves_from(from).include?(square)
        when "K"
          (target_file - file_index).abs <= 1 &&
            (target_rank - (8 - row_index)).abs <= 1 &&
            (target_file != file_index || target_rank != 8 - row_index)
        else
          false
        end
      end
    end
  end

  def encode_board(position)
    position.map do |rank|
      empty_squares = 0

      encoded_rank = rank.each_with_object("") do |piece, result|
        if piece.nil?
          empty_squares += 1
        else
          result << empty_squares.to_s if empty_squares.positive?
          empty_squares = 0
          result << piece
        end
      end

      encoded_rank << empty_squares.to_s if empty_squares.positive?
      encoded_rank
    end.join("/")
  end
end
