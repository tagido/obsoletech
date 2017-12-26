#
#   dvd_common_utils.rb
#   ===================
#   Common DVD functions
#
#   Copyright (C) 2016 Pedro Mendes da Silva 
# 
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

require_relative "../../../zerosociety/framework/scripts/framework_utils.rb"
require_relative "dvd_report_common.rb"

#
# DVD structure
#

def get_DVD_MediaInfo_extended

	result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"

	if (result == false) 
		print "#### Could not read DVD structure, exiting ... \n"
		exit
	end	

	stats_raw = `type #{TARGET_PATH}\\dvd_info.media_info.txt`

	print stats_raw

	mediainfo = OpenStruct.new
	
	mediainfo.n_sessions =         stats_raw.scan(/Number of Sessions:    ([0-9]+)/)[0][0]
	mediainfo.n_tracks =           stats_raw.scan(/Number of Tracks:      ([0-9]+)/)[0][0]
	mediainfo.disc_status =        stats_raw.scan(/Disc status:           (.+)/)[0][0]
	mediainfo.track_status =       stats_raw.scan(/Track State:           (.+)/)
	mediainfo.free_blocks =        stats_raw.scan(/Free Blocks:( +)?([0-9]+)?(\*2KB)/)
	mediainfo.next_write_address = stats_raw.scan(/Next Writable Address:( +)?([0-9]+)?(\*2KB)/)
	mediainfo.track_start_address = stats_raw.scan(/Track Start Address:( +)?([0-9]+)?(\*2KB)/)
	mediainfo.track_size =         stats_raw.scan(/Track Size:( +)?([0-9]+)?(\*2KB)/)
	
	print "\n\nN_sessions = #{mediainfo.n_sessions}\n"
	print "disc status = #{mediainfo.disc_status}\n"
	print "No. of tracks = #{mediainfo.n_tracks}\n"
	print "  tracks status = #{mediainfo.track_status}\n"
	print "  next_write_address = #{mediainfo.next_write_address}\n"
	print "  track_start = #{mediainfo.track_start_address}\n"
	print "  track_size = #{mediainfo.track_size}\n"
	print "  free_blocks = #{mediainfo.free_blocks}\n"
	print "#{mediainfo.track_size[0][1]}\n"
	
	print "===============================\n\n"
	
	print "#{mediainfo.n_sessions.to_i() == 1}\n"
	print "#{mediainfo.n_tracks.to_i() == 2}\n"
	
	
	#
	# Check DVD signatures
	#
	
	
	# Check if it a DVD+VR
	if ( (mediainfo.n_sessions.to_i() == 1) and (mediainfo.n_tracks.to_i() == 2) and (mediainfo.track_size[0][1].to_i() == DVD_VR_FIRST_TRACK_SIZE))
		mediainfo.is_dvd_vr = true
	else
		mediainfo.is_dvd_vr = false
	end
	
	# Check if it is finalized
	if ( (mediainfo.disc_status == "appendable") )
		mediainfo.is_finalized = false
	else
		mediainfo.is_finalized = true
	end
	
	print "  finalized = #{mediainfo.is_finalized}\n"
	print "  dvd+vr ?  = #{mediainfo.is_dvd_vr}\n"
	
	return mediainfo
 
end

def get_No_of_DVD_titles dvd_path

	if (dvd_path.nil?)
		puts "Invalid dvd_path!"
		exit -1
	end


	result = system "\"#{HANDBRAKECLI_PATH}HandBrakeCLI.exe\" --scan -t 0 -i #{dvd_path} 2> dvd_chapters.all_titles.handbrake.txt"

	if (result == false) 
	  print "#### Could not read DVD structure, exiting ... \n"
	  exit
	end

	stats_raw = `type dvd_chapters.all_titles.handbrake.txt`

	print stats_raw

	# ex: [20:05:39] scan: DVD has 3 title(s)

	n_titles = stats_raw.scan(/DVD has ([0-9]+) title/)
	
	if (n_titles.length > 0)

		print "[DVD]n_titles=#{n_titles[0][0]}\n"
	else
		
		n_titles = stats_raw.scan(/BD has ([0-9]+) title/)
		print "[BD]n_titles=#{n_titles[0][0]}\n"
	end

end

def get_VOB_file_names

   file_names = `cmd.exe /c dir /b /s #{DVD_PATH}VTS_0#{DVD_VTS_INDEX}_*.VOB` 

   concat_filenames = file_names.gsub(/\n/, "|").chomp('|')

   puts "VOB files: #{concat_filenames}\n"
   
   return concat_filenames
end

#
# RAW data extraction
#

def extract_raw_data_from_dvd_sector_to_the_end dvd_sector_address, file_name, dvd_path


   dvd_stream_command = "\"#{DD_PATH}dd.exe\" bs=2048 skip=#{dvd_sector_address} if=\\\\.\\#{dvd_path}"
   
   conv_command = dvd_stream_command + "> #{file_name}"

   puts "#{conv_command}\n"
   dvd_report_print "(+)== Running RAW extraction for DVD ... extracting to #{file_name}\n"
   system "#{conv_command}\n"
   
end

#
# External tools dependencies
#
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
