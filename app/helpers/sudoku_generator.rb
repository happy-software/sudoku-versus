# sudoku_generator.rb
#
# Given a solved board (flat 81-element array) and a target difficulty symbol,
# returns a new 81-element array with cells replaced by nil to match that difficulty.
#
# Usage:
#   generator = SudokuGenerator.new(solved_board)
#   puzzle    = generator.generate(:hard)
#
# Difficulty bands (determined by which solving techniques are required):
#   :easy      — naked singles + hidden singles only
#   :medium    — requires naked/hidden pairs or triples
#   :hard      — requires X-wing or Swordfish patterns
#   :very_hard — requires bifurcation (trial-and-error / forcing chains)

class SudokuGenerator
  DIFFICULTIES = %i[easy medium hard very_hard].freeze

  # Each technique is assigned a weight. The puzzle's score is the *maximum*
  # weight technique ever required during solving (not the sum), so a puzzle
  # that needs X-wing once outranks one that needs a thousand hidden singles.
  TECHNIQUE_WEIGHTS = {
    naked_single:  1,
    hidden_single: 2,
    naked_pair:    3,
    hidden_pair:   4,
    naked_triple:  5,
    hidden_triple: 6,
    x_wing:        7,
    swordfish:     8,
    bifurcation:   9
  }.freeze

  # Score ranges that map to each difficulty label.
  DIFFICULTY_RANGES = {
    easy:      (1..2),
    medium:    (3..4),
    hard:      (5..7),
    very_hard: (8..9)
  }.freeze

  def initialize(solved_board)
    raise ArgumentError, "Board must have 81 elements" unless solved_board.size == 81
    raise ArgumentError, "Board must be fully solved (no nils)" if solved_board.any?(&:nil?)

    @solved_board = solved_board.map(&:to_i)
  end

  # Returns a 81-element array with nils representing blank cells.
  def generate(difficulty)
    raise ArgumentError, "Unknown difficulty: #{difficulty}" unless DIFFICULTIES.include?(difficulty)

    target_range = DIFFICULTY_RANGES[difficulty]
    cells        = (0..80).to_a.shuffle

    # Start with a full board and remove cells one at a time.
    puzzle = @solved_board.dup

    cells.each do |idx|
      original = puzzle[idx]
      puzzle[idx] = nil

      # A valid puzzle must have exactly one solution.
      unless unique_solution?(puzzle)
        puzzle[idx] = original
        next
      end

      score = rate(puzzle)

      # If we've overshot the target, put the cell back and try a different one.
      if score > target_range.max
        puzzle[idx] = original
      end

      # Stop early once we're solidly in the target range and have removed
      # enough cells to make the puzzle feel like that difficulty.
      break if score >= target_range.min && blank_count(puzzle) >= min_blanks_for(difficulty)
    end

    puzzle
  end

  # Returns the difficulty score (1–9) of a given puzzle.
  # Lower = easier. The score is the maximum technique weight used.
  def rate(puzzle)
    _, max_technique = solve_with_techniques(puzzle.dup)
    max_technique
  end

  private

  # ---------------------------------------------------------------------------
  # Solving engine
  # ---------------------------------------------------------------------------

  # Returns [solved_board_or_nil, max_technique_weight].
  # solved_board_or_nil is nil when the puzzle couldn't be solved.
  def solve_with_techniques(board)
    candidates = build_candidates(board)
    max_weight = 0

    loop do
      progress = false

      # Try each technique in order of difficulty.
      [
        [:naked_single,  method(:apply_naked_singles)],
        [:hidden_single, method(:apply_hidden_singles)],
        [:naked_pair,    method(:apply_naked_pairs)],
        [:hidden_pair,   method(:apply_hidden_pairs)],
        [:naked_triple,  method(:apply_naked_triples)],
        [:hidden_triple, method(:apply_hidden_triples)],
        [:x_wing,        method(:apply_x_wing)],
        [:swordfish,     method(:apply_swordfish)]
      ].each do |technique, applier|
        changed = applier.call(board, candidates)
        if changed
          weight = TECHNIQUE_WEIGHTS[technique]
          max_weight = weight if weight > max_weight
          progress = true
          break # restart the technique loop from the easiest technique
        end
      end

      break if board.none?(&:nil?)   # solved!
      break unless progress          # stuck — need bifurcation or unsolvable
    end

    if board.any?(&:nil?)
      # Resort to bifurcation.
      result = bifurcate(board, candidates)
      return [nil, TECHNIQUE_WEIGHTS[:bifurcation]] unless result

      [result, TECHNIQUE_WEIGHTS[:bifurcation]]
    else
      [board, max_weight]
    end
  end

  # Rebuild the full candidate sets from scratch.
  def build_candidates(board)
    candidates = Array.new(81) { (1..9).to_a }

    board.each_with_index do |val, idx|
      next unless val

      candidates[idx] = []
      peers_of(idx).each { |p| candidates[p].delete(val) }
    end

    candidates
  end

  # ---------------------------------------------------------------------------
  # Technique: Naked Single
  # A cell with exactly one candidate — place it.
  # ---------------------------------------------------------------------------
  def apply_naked_singles(board, candidates)
    changed = false

    board.each_with_index do |val, idx|
      next if val
      next unless candidates[idx].size == 1

      place(board, candidates, idx, candidates[idx].first)
      changed = true
    end

    changed
  end

  # ---------------------------------------------------------------------------
  # Technique: Hidden Single
  # Within a house, a digit appears as a candidate in only one cell.
  # ---------------------------------------------------------------------------
  def apply_hidden_singles(board, candidates)
    changed = false

    each_house do |house|
      (1..9).each do |digit|
        positions = house.select { |idx| candidates[idx].include?(digit) }
        next unless positions.size == 1

        idx = positions.first
        next if board[idx] # already placed

        place(board, candidates, idx, digit)
        changed = true
      end
    end

    changed
  end

  # ---------------------------------------------------------------------------
  # Technique: Naked Pair
  # Two cells in the same house share exactly the same two candidates.
  # Those two digits can be eliminated from all other cells in that house.
  # ---------------------------------------------------------------------------
  def apply_naked_pairs(board, candidates)
    apply_naked_subset(board, candidates, 2)
  end

  def apply_naked_triples(board, candidates)
    apply_naked_subset(board, candidates, 3)
  end

  def apply_naked_subset(board, candidates, size)
    changed = false

    each_house do |house|
      empties = house.reject { |idx| board[idx] }
      empties.combination(size) do |combo|
        union = combo.flat_map { |idx| candidates[idx] }.uniq
        next unless union.size == size

        # These `size` digits are locked into these `size` cells.
        # Remove them from every other empty cell in the house.
        (empties - combo).each do |idx|
          before = candidates[idx].size
          candidates[idx] -= union
          changed = true if candidates[idx].size < before
        end
      end
    end

    changed
  end

  # ---------------------------------------------------------------------------
  # Technique: Hidden Pair / Triple
  # Within a house, N digits appear only within the same N cells.
  # All other candidates can be removed from those cells.
  # ---------------------------------------------------------------------------
  def apply_hidden_pairs(board, candidates)
    apply_hidden_subset(board, candidates, 2)
  end

  def apply_hidden_triples(board, candidates)
    apply_hidden_subset(board, candidates, 3)
  end

  def apply_hidden_subset(board, candidates, size)
    changed = false

    each_house do |house|
      empties = house.reject { |idx| board[idx] }

      # Find digits that appear in exactly 2..size cells within this house.
      digit_positions = {}
      (1..9).each do |digit|
        positions = empties.select { |idx| candidates[idx].include?(digit) }
        digit_positions[digit] = positions if positions.size.between?(2, size)
      end

      digit_positions.keys.combination(size) do |digits|
        positions = digits.flat_map { |d| digit_positions[d] }.uniq
        next unless positions.size == size

        # These digits are locked into these cells — strip all other candidates.
        positions.each do |idx|
          before = candidates[idx].size
          candidates[idx] &= digits
          changed = true if candidates[idx].size < before
        end
      end
    end

    changed
  end

  # ---------------------------------------------------------------------------
  # Technique: X-Wing
  # If a digit appears in exactly two cells in each of two rows, and those
  # cells share the same two columns, the digit can be eliminated from those
  # columns everywhere else.
  # ---------------------------------------------------------------------------
  def apply_x_wing(board, candidates)
    apply_fish(board, candidates, 2)
  end

  # ---------------------------------------------------------------------------
  # Technique: Swordfish (3-row fish)
  # ---------------------------------------------------------------------------
  def apply_swordfish(board, candidates)
    apply_fish(board, candidates, 3)
  end

  def apply_fish(board, candidates, size)
    changed = false

    (1..9).each do |digit|
      # Check rows as base, columns as cover.
      changed |= fish_direction(candidates, digit, size, :row)
      # Check columns as base, rows as cover.
      changed |= fish_direction(candidates, digit, size, :col)
    end

    changed
  end

  def fish_direction(candidates, digit, size, base_type)
    changed = false

    # For each row (or col), find the columns (or rows) where the digit appears.
    lines = (0..8).map do |i|
      cells = base_type == :row ? row_indices(i) : col_indices(i)
      cols  = cells.select { |idx| candidates[idx].include?(digit) }.map do |idx|
        base_type == :row ? idx % 9 : idx / 9
      end
      cols
    end

    # We need base lines where the digit appears in 2..size positions.
    eligible = (0..8).select { |i| lines[i].size.between?(2, size) }

    eligible.combination(size) do |base_lines|
      cover_lines = base_lines.flat_map { |i| lines[i] }.uniq
      next unless cover_lines.size == size

      # Eliminate the digit from all other cells in the cover lines.
      cover_lines.each do |cover_idx|
        cover_cells = base_type == :row ? col_indices(cover_idx) : row_indices(cover_idx)

        cover_cells.each do |cell|
          # Skip cells that are part of the base.
          base_row_or_col = base_type == :row ? cell / 9 : cell % 9
          next if base_lines.include?(base_row_or_col)
          next unless candidates[cell].include?(digit)

          candidates[cell].delete(digit)
          changed = true
        end
      end
    end

    changed
  end

  # ---------------------------------------------------------------------------
  # Bifurcation (last resort)
  # Pick the cell with fewest candidates, try each, recurse.
  # ---------------------------------------------------------------------------
  def bifurcate(board, candidates)
    # Find the unsolved cell with fewest candidates.
    idx = board.each_with_index
               .select { |v, _| v.nil? }
               .min_by { |_, i| candidates[i].size }&.last

    return nil unless idx
    return nil if candidates[idx].empty?

    candidates[idx].each do |digit|
      board_copy      = board.dup
      candidates_copy = candidates.map(&:dup)

      place(board_copy, candidates_copy, idx, digit)
      result, = solve_with_techniques(board_copy)
      return result if result && result.none?(&:nil?)
    end

    nil
  end

  # ---------------------------------------------------------------------------
  # Uniqueness check — ensures exactly one solution exists.
  # We solve normally; if bifurcation is needed we count branches.
  # ---------------------------------------------------------------------------
  def unique_solution?(puzzle)
    count_solutions(puzzle.dup, build_candidates(puzzle.dup), 0) == 1
  end

  def count_solutions(board, candidates, count)
    return count + 1 if board.none?(&:nil?)
    return count    if count >= 2 # early exit — we only care about 1 vs. many

    # Apply naked singles silently to collapse obvious cells.
    loop do
      changed = false
      board.each_with_index do |val, idx|
        next if val
        if candidates[idx].size == 1
          place(board, candidates, idx, candidates[idx].first)
          changed = true
        elsif candidates[idx].empty?
          return count # contradiction — dead end
        end
      end
      break unless changed
    end

    return count + 1 if board.none?(&:nil?)

    # Pick the unsolved cell with the fewest remaining candidates (MRV heuristic).
    idx = board.each_with_index
               .select { |v, _| v.nil? }
               .min_by { |_, i| candidates[i].size }
            &.last

    return count unless idx

    candidates[idx].each do |digit|
      b2 = board.dup
      c2 = candidates.map(&:dup)
      place(b2, c2, idx, digit)
      count = count_solutions(b2, c2, count)
      break if count >= 2
    end

    count
  end

  # ---------------------------------------------------------------------------
  # House / index helpers
  # ---------------------------------------------------------------------------

  def row_indices(r) = (r * 9..r * 9 + 8).to_a
  def col_indices(c) = (0..8).map { |r| r * 9 + c }
  def box_indices(b)
    br = (b / 3) * 3
    bc = (b % 3) * 3
    (br..br + 2).flat_map { |r| (bc..bc + 2).map { |c| r * 9 + c } }
  end

  def each_house(&block)
    (0..8).each { |i| yield row_indices(i) }
    (0..8).each { |i| yield col_indices(i) }
    (0..8).each { |i| yield box_indices(i) }
  end

  def peers_of(idx)
    r = idx / 9
    c = idx % 9
    b = (r / 3) * 3 + (c / 3)

    (row_indices(r) + col_indices(c) + box_indices(b)).uniq - [idx]
  end

  # Place a digit, remove it from all peer candidate lists.
  def place(board, candidates, idx, digit)
    board[idx]      = digit
    candidates[idx] = []
    peers_of(idx).each { |p| candidates[p].delete(digit) }
  end

  def blank_count(puzzle)
    puzzle.count(&:nil?)
  end

  # Approximate minimum blanks per difficulty to feel right.
  def min_blanks_for(difficulty)
    { easy: 32, medium: 42, hard: 52, very_hard: 58 }[difficulty]
  end
end


# ---------------------------------------------------------------------------
# Quick smoke test (remove or guard with __FILE__ == $0 in production)
# ---------------------------------------------------------------------------
if __FILE__ == $0
  # A known valid solved board.
  solved = [
    5,3,4, 6,7,8, 9,1,2,
    6,7,2, 1,9,5, 3,4,8,
    1,9,8, 3,4,2, 5,6,7,
    8,5,9, 7,6,1, 4,2,3,
    4,2,6, 8,5,3, 7,9,1,
    7,1,3, 9,2,4, 8,5,6,
    9,6,1, 5,3,7, 2,8,4,
    2,8,7, 4,1,9, 6,3,5,
    3,4,5, 2,8,6, 1,7,9
  ]

  %i[easy medium hard very_hard].each do |difficulty|
    gen    = SudokuGenerator.new(solved)
    puzzle = gen.generate(difficulty)
    blanks = puzzle.count(&:nil?)
    score  = gen.rate(puzzle)
    puts "#{difficulty}: #{blanks} blanks, technique score #{score}"
  end
end