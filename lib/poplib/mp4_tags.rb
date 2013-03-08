unless $LOAD_PATH.include?(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end
require 'cmd'

module Poplib    
  class Mp4Tags
    attr_accessor :data
    def initialize(mp4file)
      @data = {
        "Name" => {"optstr" => "-s", "value" => ""},
        "Artist" => {"optstr" => "-a", "value" => ""},
        "Composer" => {"optstr" => "-w", "value" => ""},
        "Encoded with" => {"optstr" => "-E", "value" => ""},
        "Encoded by" => {"optstr" => "-e", "value" => ""},
        "Release Date" => {"optstr" => "-y", "value" => ""},
        "Album" => {"optstr" => "-A", "value" => ""},
        "Track" => {"optstr" => "-t", "value" => "1"},
        "Tracks" => {"optstr" => "-T", "value" => "1"},
        "Disk" => {"optstr" => "-d", "value" => "1"},
        "Disks" => {"optstr" => "-D", "value" => "1"},
        "Genre" => {"optstr" => "-g", "value" => ""},
        "Grouping" => {"optstr" => "-G", "value" => ""},
        "BPM" => {"optstr" => "-b", "value" => "0"},
        "Comments" => {"optstr" => "-c", "value" => ""},
        "Album Artist" => {"optstr" => "-R", "value" => ""},
        "Copyright" => {"optstr" => "-C", "value" => ""},
        "HD Video" => {"optstr" => "-H", "value" => 1},
        "Media Type" => {"optstr" => "-i", "value" => ""},
        "TV Show" => {"optstr" => "-S", "value" => ""},
        "TV Network" => {"optstr" => "-N", "value" => ""},
        "TV Episode Number" => {"optstr" => "-o", "value" => ""},
        "Short Description" => {"optstr" => "-m", "value" => ""},
        "Long Description" => {"optstr" => "-l", "value" => ""},
        "TV Episode" => {"optstr" => "-M", "value" => ""},
        "TV Season" => {"optstr" => "-n", "value" => ""},
        "cnID" => {"optstr" => "-I", "value" => "0"},
        "Lyrics" => {"optstr" => "-L", "value" => ""},
      }
      if(File.exists? mp4file)
        @mp4file = mp4file
        refresh
      else
        raise "ERROR Poplib::Mp4Tags::initialize: %s does not exist!"
      end
    end
    def refresh
      cmd = Poplib::Cmd.new("mp4info \"%s\"" % @mp4file)
	    rtn = cmd.run
	    rtn = rtn.gsub(/Lyrics:[\n\r ]+/, "Lyrics:\n")
	    lines = rtn.split(/\n/)
	    lines.each do |line|
	      if((/Track\:/ =~ line) == nil && (/Disk\:/ =~ line) == nil && line != nil)
	        nv = line.strip().split(/\:/)
	        begin
	          if(nv != nil && nv[0] != nil && nv[1] != nil)
	            @data[nv[0].strip()]['value'] = nv[1].strip()
            end
          rescue => e
            puts e
          end
        else
          md = line.match(/(Track|Disk)\: ([0-9]+) of ([0-9]+)/)
          @data[md[1]]['value'] = md[2]
          @data[md[1]+"s"]['value'] = md[3]
        end
      end
    end
    def to_s
      return @data.to_s
    end
    def save
      cmdstr = "mp4tags "
      @data.each do |key, opt|
        if(opt['value'] != nil && opt['optstr'] != nil)
          cmdstr << opt["optstr"] << " \"" << opt["value"] << "\" "
        end
      end
      cmdstr << "\"" << @mp4file << "\""
      cmd = Poplib::Cmd.new(cmdstr)
      rtn = cmd.run
      # rtn << cmd.sestr
      if(rtn == "")
	      return cmdstr
	    else
	      return rtn
	    end   
    end
  end
end