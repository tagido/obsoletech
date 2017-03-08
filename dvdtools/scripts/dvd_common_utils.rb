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


#
# DVD structure
#

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
# External tools dependencies
#
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
