unless $LOAD_PATH.include?(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end
require 'cmd'

module Poplib    
  class Mp4Info
    attr_reader :artist
    attr_reader :encodedWith
    attr_reader :realeaseDate
    attr_reader :album
    attr_reader :genre
    attr_reader :comments
    attr_reader :copyright
    attr_reader :mediaType
    attr_reader :desc
    attr_reader :mp4file
  
    def initialize(mp4file)
      @artist = nil
      @encodedWith = nil
      @releaseDate = nil
      @album = nil
      @genre = nil
      @comments = nil
      @copyright = nil
      @mediaType = nil
      @desc = nil
      @mp4file = mp4file
	    cmd = Poplib::Cmd.new("mp4info \"%s\"" % @mp4file)
	    rtn = cmd.run
	    lines = rtn.split(/\n/)
	    lines.each do |line|
	      nv = line.strip().split(/\:/)
	      if(nv[0].strip() == "Artist")
	        @artist = nv[1].strip().split(" / ")
        elsif(nv[0].strip() == "Encoded with")
          @encodedWith = nv[1].strip()
        elsif(nv[0].strip() == "Release Date")
          @releaseDate = nv[1].strip()
        elsif(nv[0].strip() == "Album")
          @album = nv[1].strip()
        elsif(nv[0].strip() == "Genre")
          @genre = nv[1].strip().split(' / ')
        elsif(nv[0].strip() == "Comments")
          @comments = nv[1].strip()
        elsif(nv[0].strip() == "Copyright")
          @copyright = nv[1].strip()
        elsif(nv[0].strip() == "Media Type")
          @mediaType = nv[1].strip()
        elsif(nv[0].strip() == "Short Description")
          @desc = nv[1].strip()
        end
      end
    end
    def to_s
      return "Artist: %s\nEncoded with: %s\nRelease Date: %s\nAlbum: %s\nGenre: %s\nComments: %s\nCopyright: %s\nMedia Type: %s\nDescription: %s\n" %
              [@artist, @encodedWith, @releaseDate, @album, @genre, @comments, @copyright, @mediaType, @desc]
    end
    def genre
      return @genre
    end
  end
end