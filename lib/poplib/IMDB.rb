require 'uri'
require 'net/http'
module Poplib
  module IMDB
    # define our constants
    $imdb_url = "http://www.imdb.com/"
    $ask_uri_fmt = $imdb_url + "find?q=%s&s=tt"  # url for the imdb search
    $ask2_uri_fmt = $imdb_url + "search/title?title=%s"
    $title_uri_fmt = $imdb_url + "title/tt%s/"
    $block_regex_fmt = "<p><b>Titles \\(%s Matches\\)<\\/b> \\(Displaying ([0-9]+) Results{0,1}\\)<table><tr>(.*)<\\/tr><\\/table> <\\/p>" 
    $title_regex = /<a href="\/title\/tt([0-9]+)\/" onclick="\(new Image\(\)\)\.src\=\'\/rg\/find-title-[0-9]+\/title_.*\/images\/b\.gif\?link=\/title\/tt[0-9]+\/\'\;\">(.*)<\/a> \(([0-9]{4})\)/
    $title_regex_pre = /<a href="\/title\/tt([0-9]+)\/" onclick="\(new Image\(\)\)\.src\=\'\/rg\/find-title-[0-9]+\/title_.{0,7}\/images\/b\.gif\?link=\/title\/tt[0-9]+\/\'\;\">/
    $title_regex_post = /<\/a> \(([0-9]{4}).{0,4}\)/
    $title_desc_regex_pre = /<p itemprop="description">/
    $title_desc_regex_post = /<\/p>/
    $title_image_regex_pre = /id="img_primary"/
    $title_image_regex_post = /<img src="(.+)"[ \t\n\r]+style=/
    $title_tt_regex = /"\/title\/tt([0-9]+)\/"/
    $title_name_regex_pre = /<h1 class="header" itemprop="name">/
    $title_name_regex_post = /<span/
    $title_year_regex_pre = /<a href="\/year\//
    $title_year_regex_post = /\/">/
    
    class Title 
      attr_reader :id, :uri, :uri_str
      
      TO_S_FMT = "%s (%s) [%s]\nDescription:\n\t%s\nImage: %s\n"
      
      def initialize(id, title = nil, year = nil)
        @title = title
        @id = id
        @year = year
        @uri_str = $title_uri_fmt % @id
        @uri = URI(@uri_str)
        @html = nil
      end
      
      def ==(y)
        if y.is_a? String
          return @id == y
        end
        return false
      end
      
      def to_s
        return TO_S_FMT % [self.title, self.year, self.uri_str, self.description, self.image_url]
      end
      
      def download
        @html = Net::HTTP.get(@uri)
      end
      
      def description
        self.download if @html == nil
        d = @html.partition($title_desc_regex_pre)
        (d[2] == nil) ? (return nil) : (return d[2].partition($title_desc_regex_post)[0].strip)
      end
      
      def image_url
        self.download if @html == nil
        i = @html.partition($title_image_regex_pre)
        return nil if i[2] == nil
        m = i[2].match($title_image_regex_post)
        (m == nil) ? (return nil) : (return m[1])
      end
      
      def title
        return @title if @title != nil
        self.download if @html == nil
        p1 = @html.partition($title_name_regex_pre)
        return '' if(p1[2]) == nil
        p2 = p1[2].partition($title_name_regex_post)
        return '' if(p2[0] == nil)
        @title = p2[0].strip
        return @title
      end   
      
      def year
        return @year if @year != nil
        self.download if @html == nil
        p1 = @html.partition($title_year_regex_pre)
        return '' if(p1[2]) == nil
        p2 = p1[2].partition($title_year_regex_post)
        return '' if(p2[0] == nil)
        @year = p2[0].strip
        return @year
      end
    
      def desc_to_mac_clipboard
        IO.popen('pbcopy', 'w').write(self.description)
      end
    end
    
    class Search
      attr_reader :popular_titles, :exact_titles, :part_titles, :approx_titles, :search_str, :ask_uri, :ask_res
      attr_writer :popular_titles, :exact_titles, :part_titles, :approx_titles
        
      def initialize(search_str)
        self.search_str(search_str)
        @popular_titles = []
        @exact_titles = []
        @part_titles = []
        @approx_titles = []
        @titles = []
      end
      
      def search
        # create our asking for uri
        @ask_uri = URI($ask_uri_fmt % @search_str)
        # get our result
        @ask_res = Net::HTTP.get(@ask_uri)
        self.search2
        @popular_titles = parseBlock(/<p><b>Popular Titles<\/b> \(Displaying ([0-9]+) Results{0,1}\)<table><tr>.*/) 
        @exact_titles = parseBlock(/<p><b>Titles \(Exact Matches\)<\/b> \(Displaying ([0-9]+) Results{0,1}\)<table><tr>(.*)<\/tr><\/table> <\/p>/)  
        @part_titles =   parseBlock(/<p><b>Titles \(Partial Matches\)<\/b> \(Displaying ([0-9]+) Results{0,1}\)<table><tr>.*<\/tr><\/table> <\/p>/)  
        @approx_titles =  parseBlock(/<p><b>Titles \(Approx Matches\)<\/b> \(Displaying ([0-9]+) Results{0,1}\)<table><tr>.*<\/tr><\/table> <\/p>/)  
      end
      
      def search_str str
        @o_search_str = str
        @search_str = str.gsub(/[ \n\t\c\r]/, '+')
        @search_uri = URI($ask_uri_fmt % @search_str)
        @search2_uri = URI($ask2_uri_fmt % @search_str)
      end
      
      def to_s
        # puts "%s:\t%s" % [@ask_uri, @ask_res] if(self.nothing?) 
        rtn = "Search Results:\n"
        if @popular_titles != nil
          rtn += "Popular Matches:\n"
          @popular_titles.each do |t| 
            rtn += "\t%s (%s) [%s]\n\tDescription:\n\t\t\t%s\n\tImage URL: %s\n" % [t.title, t.year, t.uri_str, t.description, t.image_url]
          end
        end
       
        if @exact_titles != nil
          rtn += "Exact Matches:\n"
          @exact_titles.each do |t|
            rtn += "\t%s (%s) [%s]\n\tDescription:\n\t\t\t%s\n\tImage URL: %s\n" % [t.title, t.year, t.uri_str, t.description, t.image_url]
          end
        end
        
        if @part_titles != nil
          rtn += "Partial Matches:\n"
          @part_titles.each do |t|
            rtn += "\t%s (%s) [%s]\n\tDescription:\n\t\t\t%s\n\tImage URL: %s\n" % [t.title, t.year, t.uri_str, t.description, t.image_url]
          end
        end
        
        if @approx_titles != nil
          rtn += "Approx Matches:\n"
          @approx_titles.each do |t|
            rtn += "\t%s (%s) [%s]\n\tDescription:\n\t\t\t%s\n\tImage URL: %s\n" % [t.title, t.year, t.uri_str, t.description, t.image_url]
          end
        end
        
        if @titles != nil
          rtn += "Title Search Matches:\n"
          @titles.each do |t|
            rtn += "\t%s (%s) [%s]\n\tDescription:\n\t\t\t%s\n\tImage URL: %s\n" % [t.title, t.year, t.uri_str, t.description, t.image_url]
          end
        end
        return rtn
      end
      
      def getTop
        if @titles != nil && @titles[0] != nil
          return @titles[0]
        elsif @popular_titles != nil && @popular_titles[0] != nil
          return @popular_titles[0]
        elsif @exact_titles != nil && @exact_titles[0] != nil
          return @exact_titles[0]
        elsif @part_titles != nil&& @part_titles[0] != nil
          return @part_titles[0]
        elsif @approx_titles != nil && @approx_titles[0] != nil
          return @approx_titles[0]
        else
          return false
        end
      end
      
      def openTop 
        cmd = nil
        t = self.getTop
        puts "Opening: %s" % t
        cmd = "open \"%s\"" % t.image_url unless t === false
        if cmd != nil
          puts cmd
          `#{cmd}`
        end
        puts "Placing Description in Clipboard: SUCCESS"
        t.desc_to_mac_clipboard
      end
      
      def count
        (@popular_titles == nil) ? (ptc = 0) : ptc = @popular_titles.length
        (@exact_titles == nil) ? (etc = 0) : etc = @exact_titles.length
        (@part_titles == nil) ? (prtc = 0) : prtc = @part_titles.length
        (@approx_titles == nil) ? (atc = 0) : atc = @approx_titles.length
        (@titles == nil) ? (ttc = 0) : ttc = @titles.length
        return ptc + etc + prtc + atc + ttc
      end
      
      def results
        rtn = Array.new()
        unless @popular_titles == nil; rtn.concat(@popular_titles); end
        unless @exact_titles == nil; rtn.concat(@exact_titles);end
        unless @part_titles == nil; rtn.concat(@part_titles); end
        unless @approx_titles == nil; rtn.concat(@approx_titles); end
        unless @titles == nil; rtn.concat(@titles); end
        return rtn
      end
      
      def nothing?
        c = self.count
        (c == 0) ? (return true) : (return false)
      end
      
      protected
      
        def search2
           # puts "Get " + @search2_uri.to_s
           @ask_res = Net::HTTP.get(@search2_uri)
           # puts "Got " + @search2_uri.to_s
           s = @ask_res.dup
           i = 0
           while (m = s.match($title_tt_regex))
             if(!@titles.include?(m[1]))
               t = Title.new m[1]
               @titles.push t
             end
             s = m.post_match
           end
         end
      
      private
      
        def getTitles(block)
          rtn = Array.new
          nb = String.new(block)
          t = nb.partition $title_regex_pre
          while t[0] != $title_regex_pre && t[1] != nil
            id_m = t[1].match $title_regex_pre
            break if id_m == nil
            p = t[2].partition $title_regex_post
            break if p[1] == nil
            year_m = p[1].match $title_regex_post
            year_m = "????" if year_m == nil
            title = p[0]
            t = t[2].partition $title_regex_pre
            mov = Title.new id_m[1], title, year_m[1]
            rtn.push mov
          end
          return rtn
        end
        
        def parseBlock(idx_on_regex)
          m = @ask_res.match(idx_on_regex)  
          if m != nil
            mb = m[0][0, m[0].index(/<\/tr><\/table>/)]
            return getTitles(mb)
          end
        end
    end
  end
end