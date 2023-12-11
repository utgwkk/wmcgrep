require "natto"

require_relative "./ng_word"

def ignorable(n)
  n.is_eos? || n.feature.include?("記号")
end

class Node
  attr_reader :yomi, :start_pos, :end_pos

  def initialize(mecab_node, start_pos, end_pos)
    @mecab_node = mecab_node

    _, _, _, _, _, _, _, yomi, _ = mecab_node.feature.split ','
    @yomi = yomi
    @start_pos = start_pos
    @end_pos = end_pos
  end
end

nodes = []
pos_map = []
nm = Natto::MeCab.new

pos = 0
STDIN.each_line {|text|
  nm.parse(text) { |n|
    if ignorable(n)
      pos += n.surface.length
      next
    end

    node = Node.new(n, pos, pos + n.surface.length)
    nodes << node
    pos_map += (node.start_pos..(node.end_pos-1)).to_a
    pos += n.surface.length
  }

  hit_ranges = []

  yomi_text = nodes.map(&:yomi).join
  NG_WORDS.each { |ng_word|
    find_after = 0
    loop {
      idx = yomi_text.index(ng_word, find_after)
      if idx.nil?
        break
      end
      left = pos_map[idx]
      right = pos_map[idx + ng_word.length - 1]
      r = [left, right]

      hit_ranges << r
      find_after = idx+1
    }
  }
  hit_ranges.sort_by! {|e| e[0] }

  # merge ranges
  merged_ranges = []
  hit_ranges.each_with_index {|r, i|
    if i == 0
      merged_ranges << r
      next
    end

    mr = merged_ranges[-1] || [[-1, -1]]
    if mr[1] >= r[0]
      merged_ranges[-1][1] = r[1]
    else
      merged_ranges << r
    end
  }

  text.chars.each_with_index {|c, i|
    r = hit_ranges[0] || [[-1, -1]]
    if i == r[0]
      print "\e[31m"
    end
    print c
    if i == r[1]
      print "\e[0m"
      hit_ranges.shift
    end
  }
}
