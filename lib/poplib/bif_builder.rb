require 'tmpdir'

unless $LOAD_PATH.include?(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end

require 'cmd'

module Poplib
  class BifBuilder
    # global constants
    FFMPEG_VER_CMD = "ffmpeg -version"
    FFMPEG_EXT_CMD_FMT = "ffmpeg -i %s -r %0.2f -s 320x240 \"%s/%%08d.jpg\""
    
    # attributes
    attr_reader :ffmpeg_version, :interval, :movie_path, :bif_path, :img_path
    attr_writer :interval, :bif_path, :img_path
    
    #Initializer: this takes in one param
    # mov_file_path is the full path to the 
    # Movie file that we will generate a 
    # bif file for.
    def initialize mov_file_path, bif_path=nil, interval=10    
      #make sure ffmpeg is here...
      cmd = Poplib::Cmd.new(FFMPEG_VER_CMD)
      ffmpeg_return = cmd.run
      ffmpeg_return = cmd.sestr
      ffmpeg_rtn_space_split = ffmpeg_return.split(/[ \n]/)
      if ffmpeg_rtn_space_split[0].casecmp('ffmpeg') != 0
        raise "FAILURE: ffmpeg is not installed!"
        return nil
      else
        #since ffmpeg is installed lets capture its version...
        @ffmpeg_version = ffmpeg_rtn_space_split[1]
      end
  
      #set our movie path using the attr_writer for movie_path=  
      self.movie_path = mov_file_path
      #set up our bif_path attr, if it is null use current dir with -SD.bif 
      #on end of mov_path without extention 
      #  ie: mov_path = '/a/b/c/movie name.mp4' 
      #      then bif_path default = '/a/b/c/movie name-SD.bif'
      if bif_path == nil
        @bif_path = (@movie_path[0,@movie_path.length() - 4] + "-SD.bif").gsub(/\\/, '')
      else
        @bif_path = bif_path
      end 
      @img_path = (@bif_path[0,@bif_path.length() - 3] + "jpg")
      #set the intervals
      @interval = interval
      #class is ready to go!
    end
    
    #attr_writer for movie_path
    def movie_path= path
      #make sure the Movie file is here
      if not File.exists? path then 
        raise "FAILURE: %s does not exist." % path
        return nil 
      end
      #make sure that Movie file is a MP4
      if path[-3,3].casecmp('MP4') == 0
        @movie_path = escapeSpecialChars(path)
        # @movie_path = path
	return @movie_path
      else
        raise "FAILURE: %s is not an supported video file type (.MP4)." %path
        return nil
      end
    end
    
    public
      def buildBif gen_img=true, bif_path=nil
        if bif_path != nil then @bif_path = bif_path end
        
        @tmpdir = Dir.mktmpdir
        puts "   using temp directory: %s" % @tmpdir
        if gen_img then puts "Generate Image: %s" % @img_path end
        #@tmpdir_o = @tmpdir
        #@tmpdir = "./images"
        begin
          extractImages
          makeBif gen_img
          
        ensure
          #@tmpdir = @tmpdir_o
          FileUtils.remove_entry_secure @tmpdir
        end
      end
      
    private
    #function to extract the images of the movie file...
      def extractImages
        cmd = Poplib::Cmd.new(FFMPEG_EXT_CMD_FMT % [@movie_path, @interval.to_f/100.0, @tmpdir])
        puts "      extracting images: %s" % cmd.cmdstr
        tcmd = "mp4info %s" % @movie_path
        begin
          totalf = (`#{tcmd}`.match(/([0-9]+\.[0-9]+) sec/)[1].to_f)/10
        rescue => e
          puts e.backtrace.join "\n"
          puts "RESCUING, Carry on my son..."
          totalf = 1.0
        end
        progthread = Thread.new{
          out = $stdout.clone
          ostr = ''
          cnt = 0
          idx = -2
          while true
            cnt = Dir.entries(@tmpdir).count - 2
            percent = ((cnt.to_f/totalf.to_f)*100).to_i
            bstr = "\b" * ostr.length
            out.print bstr
            perstr = '=' * 50
            (percent == 0) ? x = 0 : x = percent/2
            perstr.insert x, ("<[%s%%]>" % percent.to_s)
            if cnt > 0 and idx > 0
              r = cnt.to_f/idx.to_f
              x = ((totalf.to_f/r) - idx.to_f).to_i
            else
              x = 0
              r = 0.0
            end
            ostr = "%s of %s: [%s] ~%s (%.2f imgs/sec)" % [cnt, totalf, perstr, Time.at(x).gmtime.strftime('%R:%S'), r] 
            out.print ostr
            sleep 1
            idx += 1
          end
        }
        sleep 3
        cmd.runBig
        progthread.kill
        puts "\n    extraction complete."
      end
    #function to make the Bif
      def makeBif gen_img=true
        magic = [0x89,0x42,0x49,0x46,0x0d,0x0a,0x1a,0x0a]
        version = 0
        #load the images array
        images = []
        imgdir = Dir.new @tmpdir
        imgdir.each do |f|
          if f[-3,3] == 'jpg'
            images.push f
          end
        end
        if images.length == 0 
          raise "NO IMAGES GENERATED!"
          return
        end
        images.sort!
        if gen_img
          sf = "%s/%08d.jpg" % [@tmpdir, (images.length()/3)]
          df = @img_path
          cmd = "cp \"%s\" \"%s\"" % [sf, df]
          puts cmd
          `#{cmd}`
        end
        puts "          Creating file: %s" % @bif_path
        bf = File.new @bif_path, "w"
        puts "    Writing magic bytes..."
        magic.each { |byte| bf.write byte.chr }
        puts "        Writing version..."
        bf.write [version].pack("I<1")
        puts "         Writing images: %s" % images.length
        bf.write [images.length].pack("I<1")
        puts "      Writing intervals: %s" % (1000*@interval.to_f)
        bf.write [(1000*@interval.to_f)].pack("I<1")
        puts "       Writing nils out..."
        until(bf.tell >= 64) 
          bf.write 0x00.chr
        end
        
        bif_tbl_size = 8 + (8 * images.length())
        img_idx = 64 + bif_tbl_size
        ts = -1
        
        puts "    Writing Image Table..."
        images.each do |img|
          sz = File.size(@tmpdir+"/"+img)
          bf.write [ts].pack("I<1")
          bf.write [img_idx].pack("I<1")
          ts += 1
          img_idx += sz
        end
        
        bf.write [0xffffffff].pack("I<1")
        bf.write [img_idx].pack("I<1")
  
        puts "       Enjecting Images ---> squirt"
        images.each do |img|
          data = File.read(@tmpdir+"/"+img)
          bf.write data
        end
        
        puts "                Closing: %s" % @bif_path
        bf.close
      end
    #function to help by escaping special charicters in the path
      def escapeSpecialChars str
        return str.gsub(/ /, '\ ').gsub(/\(/, '\(').gsub(/\)/, '\)').gsub(/\[/, '\[').gsub(/\]/, '\]').gsub("'", "\\\\'")
      end
  end
end
