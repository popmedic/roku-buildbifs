require 'net/http'
require 'open-uri'
require 'xmlsimple'

unless $LOAD_PATH.include?(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.dirname(__FILE__))
end

module Poplib  
  module PopTVDB
    $TVDB_URI_STR = 'http://www.thetvdb.com'
    $TVDB_GET_SERIES_URI_PRE_STR = 'http://www.thetvdb.com/api/GetSeries.php?seriesname='
    $TVDB_GET_SERIES_BY_ID_FMT_STR = "http://www.thetvdb.com/api/A8B8C9F3D5621481/series/%i/all"
    def PopTVDB::query(uristr)
      str = ""
      open(uristr) do |f|
        str << f.read
      end
      return str
    end
    def PopTVDB::search(search)
      xmlstr = query($TVDB_GET_SERIES_URI_PRE_STR + URI.encode(search))
      xml = XmlSimple.xml_in(xmlstr) 
      #puts "RES: " + xmlstr
      if(xml['Series'] == nil)
        raise "ERROR: %s not found in TVDB" % search
      else
        return xml['Series']
      end
    end
    def PopTVDB::getSeriesById(id)
      xmlstr = query($TVDB_GET_SERIES_BY_ID_FMT_STR % id.to_i)
      xml = XmlSimple.xml_in(xmlstr) 
      #puts "RES: " + xmlstr
      if(xml['Series'] == nil)
        raise "ERROR: %s not found in TVDB" % id
      else
        return xml
      end
    end
    def PopTVDB::getEpisodeBySeasonNumberAndEpisodeNumber(episodes, season_num, episode_num)
      #puts "\tTry 1"
      episodes.each do |episode|
        if((episode['SeasonNumber'][0].to_i == season_num.to_i) && (episode['EpisodeNumber'][0].to_i == episode_num.to_i))
          return episode
        end
      end
      #put "\tTry 2"
      episodes.each do |episode|
        if(episode['SeasonNumber'][0].to_i == season_num.to_i)
          begin
            abs_num = episode['absolute_number'][0]
            if(abs_num.to_i == episode_num.to_i)
              return episode
            end
          rescue => err
            #puts err
          end
        end
      end
      #puts "\tTry 3"
      episodes.each do |episode|
        begin
          abs_num = episode['absolute_number'][0]
          if(abs_num.to_i == episode_num.to_i)
            return episode
          end
        rescue => err
          #puts err
        end
      end
      #puts "\tTry 4"
      episodes.each do |episode|
        if(episode['EpisodeNumber'][0].to_i == episode_num.to_i)
          return episode
        end
      end
      
      #puts "\tNOTHING"
      return nil
    end
    def PopTVDB::getEpisodeIdx(episodes, episode)
      idx = 1
      episodes.each do |epi|
        if(epi["id"][0].to_i == episode["id"][0].to_i)
          return idx
        end
        idx = idx + 1
      end
      return 0
    end
    def PopTVDB::getSeasonCount(episodes)
      cnt = 0
      episodes.each do |epi|
        if (cnt < epi["SeasonNumber"][0].to_i)
          cnt = epi["SeasonNumber"][0].to_i
        end
      end
      return cnt
    end
  end
end
