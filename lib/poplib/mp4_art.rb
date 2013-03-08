unless $LOAD_PATH.include?(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end
require 'cmd'

module Poplib
  class Mp4Art
    attr_reader :mp4art
    def initialize(mp4file)
      @mp4file = mp4file
    end
    def containsArtwork?
      cmd = Poplib::Cmd.new("mp4info \"%s\"" % @mp4file)
      rtn = cmd.run
      if rtn.match(/Cover Art pieces/)
        return true
      end
      return false 
    end
    def removeArtwork
      if self.containsArtwork?
        cmd = Poplib::Cmd.new("mp4art --remove \"%s\"" % @mp4file)
        return cmd.run
      end
      return "No artwork found in file: %s" % @mp4file
    end
    def extractArtwork(size = nil, dest = nil)
      if self.containsArtwork?
        tf = "%s/%s.art[0].jpg" % [ File.dirname(@mp4file), File.basename(@mp4file, '.mp4') ]
        cmd = Poplib::Cmd.new("mp4art --extract \"%s\"" % @mp4file)
        rtn = cmd.run
        unless File.exists?(tf)
          return false
        end
      end
      if(size != nil)  
        require 'RMagick'
        img = Magick::Image.read(tf).first
        img.change_geometry!(size) { |c, r, i| i.resize!(c, r) }
        img.format = "JPG"
        if dest == nil
          img.write("%s/%s-SD.jpg" % [ File.dirname(@mp4file), File.basename(@mp4file, '.mp4') ])
        else
          img.write(dest)
        end
      else
        if dest == nil
          IO.copy_stream(tf, ("%s/%s-SD.jpg"  % [File.dirname(@mp4file), File.basename(@mp4file, '.mp4')]))
        else
          IO.copy_stream(tf, dest)
        end
      end 
      cmd = Poplib::Cmd.new("unlink \"%s\"" % tf)
      cmd.run
    end
    def attachArtwork(af)
      if self.containsArtwork?
        self.removeArtwork
      end
      cmd = Poplib::Cmd.new("mp4art --add \"%s\" \"%s\"" % [af, @mp4file])
      return cmd.run
    end
    def attachInfo(t, y, d)
      cmd = Poplib::Cmd.new("mp4tags -A \"%s\" -y \"%s\" -m \"%s\" -l \"%s\" \"%s\"" % [t, y, d, d, @mp4file])
      return cmd.run
    end
  end
end