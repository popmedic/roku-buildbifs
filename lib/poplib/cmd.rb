require 'tempfile'
module Poplib
  class Cmd
    attr_reader :cmdstr, :sostr, :sestr, :old_stdout, :old_stderr
    def initialize(cmdstr, stdin_str = nil)
      @cmdstr = cmdstr
      @sostr = @sestr = ''
      if stdin_str != nil
        @sistr = stdin_str
      else
        @sistr = ''
      end
      @old_stdout = nil
      @old_stderr = nil
    end
    def run
      @sostr = @sestr = ''
      ord, owr = IO::pipe
      erd, ewr = IO::pipe
      pid = Process.fork do  
        $stdout.reopen(owr)
        ord.close
        $stderr.reopen(ewr)
        erd.close
        exec(@cmdstr)
      end
      owr.close
      ord.each do |line| 
        @sostr = @sostr + line
      end
      ewr.close
      erd.each do |line|  
        @sestr = @sestr + line
      end
      Process.wait(pid)
      return @sostr
    end
    def runBig
      tmpo = Tempfile.new "out"
      tmpe = Tempfile.new "err"
      # first redirect stdout/stderr (so people don't see...)
      @old_stdout = $stdout.clone
      @old_stderr = $stderr.clone
      $stdout.reopen tmpo
      $stderr.reopen tmpe
      # now run the command...
      cmd = @cmdstr
      rtn = `#{cmd}`
      #set so and se strings
      @sostr = $stdout.read
      @sestr = $stderr.read
      # go back to old stdout/stderr
      $stdout.reopen @old_stdout
      $stderr.reopen @old_stderr
      #close files
      tmpo.close
      tmpe.close
      #delete temp files
      tmpo.unlink
      tmpe.unlink
      #reset old outs
      @old_stdout = nil
      @old_stderr = nil
      
      return rtn
    end
  end
end