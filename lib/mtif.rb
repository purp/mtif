require "mtif/version"
require "mtif/posts"

# Based on https://movabletype.org/documentation/appendices/import-export-format.html

class MTIF
  attr_accessor :posts

  def initialize(content)
    @posts = content.slice_after(/--------/).map {|raw_post| MTIF::Post.new(raw_post)}
  end
  
  def self.load_file(filename)
    mtif_file = File.open(filename)
    MTIF.new(mtif_file.readlines)
    mtif_file.close
  end

  def to_mtif
    posts.map(&:to_mtif).join
  end

  def save_file(filename)
    mtif_file = File.open(filename, 'w')
    mtif_file << self.to_mtif
    mtif_file.close
  end
end
