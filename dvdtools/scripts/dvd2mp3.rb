#
#   dvd2mp3.rb
#   ===================
#   Converts a DVD-Video backup to mp3 audio format 
#   (multiple audio output files are created, one for each original track)
#   Each track gets a "cover image" metadate corresponding to a video frame
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
require_relative "dvd_common_utils.rb"



def get_VOB_file_names

   file_names = `cmd.exe /c dir /b /s #{DVD_PATH}VTS_0#{DVD_VTS_INDEX}_*.VOB` 

   concat_filenames = file_names.gsub(/\n/, "|").chomp('|')

   puts "VOB files: #{concat_filenames}\n"
   
   return concat_filenames
end

def get_full_audio_flac_from_VTS_VOBs 
	#artist="DJ Estaline"
	#album= "Martelos"
	#date=  "2006"
	#genre= "HipHop"

   _file_names = get_VOB_file_names 
	
   if (_file_names == "")
		print "#### Could not find required VOBs, exiting ... \n"
		exit
   end
	
   metadata = "-metadata artist=\"#{ARTIST}\" -metadata genre=\"#{GENRE}\" -metadata date=\"#{DATE}\" -metadata album=\"#{ALBUM}\" "
   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"concat:#{_file_names}\" -map 0:#{DVD_AUDIO_STREAM_INDEX} #{metadata}  \"#{DVD_AUDIO_TMP_FILENAME}\""
   puts "#{conv_command}\n"
   puts "Fetching full audio...\n"
   result = system "#{conv_command}\n"
   
   if (result == false) 
	print "\n#### Conversion failed ! Exiting ... \n"
	#exit
   end
end


def extract_chapter_jpg_thumbnail start_time, file_index, dvd_title_number, track_filename
#ffmpeg -i test.mp4 -ss 00:01:14.35 -vframes 1 out2.png

   jpg_start_time = "0:29"

   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{DVD_AUDIO_TMP_FILENAME}\" -ss #{jpg_start_time} -vframes 1 \"#{track_filename}.jpg\""

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for Track #{file_index} ...\n"
   system "#{conv_command}\n"
   
end

def add_jpg_cover_art_to_mp3 track_filename

   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{track_filename}\" -i \"#{track_filename}.jpg\" -c copy -map 0 -map 1 -metadata:s:v title=\"Album cover\" -metadata:s:v comment=\"Cover (Front)\" \"#{track_filename}.cover.mp3\""
   #puts "conv #{start_time} .. #{end_time} \n"
   puts "#{conv_command}\n"
   puts "Adding cover art to Track #{track_filename} ...\n"
   system "#{conv_command}\n"

   system "del \"#{track_filename}\""
   system "move \"#{track_filename}.cover.mp3\" \"#{track_filename}\""
   system "del \"#{track_filename}.jpg\""
end

def convert_chapter start_time,end_time,file_index, dvd_title_number

   metadata = "-metadata title=\"Title #{dvd_title_number} - Track #{file_index}\" -metadata artist=\"#{ARTIST}\" -metadata genre=\"#{GENRE}\" -metadata date=\"#{DATE}\" -metadata album=\"#{ALBUM}\" -metadata track=\"#{file_index}\""
   track_filename = "#{TARGET_PATH}#{ARTIST} - #{ALBUM} - Title #{dvd_title_number} - Track #{file_index}.mp3"
   
   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{DVD_AUDIO_TMP_FILENAME}\" -ss #{start_time} -to #{end_time}  #{metadata} \"#{track_filename}\""
   #puts "conv #{start_time} .. #{end_time} \n"
   puts "#{conv_command}\n"
   puts "Running conversion Track #{file_index} ...\n"
   system "#{conv_command}\n"
   
   extract_chapter_jpg_thumbnail start_time, file_index, dvd_title_number, track_filename
   
   add_jpg_cover_art_to_mp3 track_filename
end



def convert_dvd_title dvd_title_number

	result = system "\"#{HANDBRAKECLI_PATH}HandBrakeCLI.exe\" --scan -t #{dvd_title_number} -i #{DVD_PATH} 2> dvd_chapters.handbrake.txt"

	if (result == false) 
	  print "#### Could not read DVD structure, exiting ... \n"
	  exit
	end

	stats_raw = `type dvd_chapters.handbrake.txt`


	print "#### caps=",stats_raw," \n"


	# ex: + 1: cells 0->0, 76438 blocks, duration 00:03:12

	caps = stats_raw.scan(/ [0-9]+: cells [0-9]+->[0-9]+, [0-9]+ blocks, duration ..:..:../)

	print "tracks=", caps, "\n\n"

	if (PAUSE == true)
	   wait_for_spacebar
	end

	#get_full_audio_flac_from_VTS_VOBs

	#"\Program Files\Handbrake\HandBrakeCLI.exe" -v 10 --main-feature -i f:\ -o carlosc.mpg
	result = system "\"#{HANDBRAKECLI_PATH}HandBrakeCLI.exe\" -t #{dvd_title_number} -a 4 -i #{DVD_PATH} -o \"#{DVD_AUDIO_TMP_FILENAME}\""

	if (result == false) 
	  print "#### Could not read audio from DVD, exiting ... \n"
	  exit
	end


	# Track
	index = 1

	# Track offset in seconds
	offset = 0

	caps.each do |i|
	   x = i.split(' ')
	   #puts "Value of local variable is #{start_str} .. #{i}"
	   #puts "Value of local variable is x =  #{x[6]}"
	   
	   seconds = conv_hhmmss_to_seconds  x[6]
	   
	   puts "Track #{index} - Duration =  #{seconds} (s) --- Offset = #{offset}"
	   
	   convert_chapter offset, offset + seconds, index, dvd_title_number
	   
	   index = index + 1;
	   offset = offset + seconds
	end

end


# TODO: automate dependencies and directories (currently hardcoded)
FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
#HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
#DVD_PATH="H:\\"
DVD_PATH="F:.\\"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"

TARGET_PATH="G:.\\"
TARGET_FILENAME="DVD - Track "
DVD_AUDIO_TMP_FILENAME="#{TARGET_PATH}dvd_full_audio.mpg"
DVD_AUDIO_STREAM_INDEX="1"
DVD_TITLE_INDEX=3
DVD_LAST_TITLE_TO_PROCESS=3


PAUSE=true

# TODO: detectar qual a pista áudio
# TODO: testar erros do HandBrakeCLI
# TODO: mover a configuração para um ficheiro separado
# TODO: extrair apenas alguns capitulos


# Set metadata
ARTIST="Unknown Artist"
ALBUM= "Unknown Album"
DATE=  "2006"
GENRE= "Dummy"


puts "dvd2mp3.rb - Converts the audio from a DVD or BD to mp3"
puts "-------------\n\n"
puts "Reading DVD structure ...\n\n"

n_dvd_titles = get_No_of_DVD_titles DVD_PATH
if (PAUSE == true)
	wait_for_spacebar
end

for i in DVD_TITLE_INDEX..DVD_LAST_TITLE_TO_PROCESS
   puts "Processing DVD Title #{i}"
   convert_dvd_title i
end



