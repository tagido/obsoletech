#
#   dvd_extract_and_stabilize.rb
#   ================================
#   Deinterlaces and stabilizes video from a DVD files
#   Extracts video from unfinalized DVD-VR or regular DVD-Video
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

require 'ostruct'
require_relative "../../../zerosociety/framework/scripts/framework_utils.rb"
require_relative "dvd_common_utils.rb"


def get_DVD_MediaInfo

	result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"

	if (result == false) 
		print "#### Could not read DVD structure, exiting ... \n"
		exit
	end	

	stats_raw = `type #{TARGET_PATH}\\dvd_info.media_info.txt`

	print stats_raw

	mediainfo = OpenStruct.new
	
	mediainfo.n_sessions = stats_raw.scan(/Number of Sessions:    ([0-9]+)/)[0][0]
	mediainfo.disc_status = stats_raw.scan(/Disc status:           (.+)/)[0][0]
	
	print "\n\nN_sessions = #{mediainfo.n_sessions}\n"
	print "disc status = #{mediainfo.disc_status}\n"
	
	print "===============================\n\n"
	
	return stats_raw
 
end

def get_VOB_file_names

   file_names = `cmd.exe /c dir /b /s #{DVD_PATH}VTS_0#{DVD_VTS_INDEX}_*.VOB` 

   concat_filenames = file_names.gsub(/\n/, "|").chomp('|')

   puts "VOB files: #{concat_filenames}\n"
   
   return concat_filenames
end



def extract_chapter_jpg_thumbnail start_time, file_index, dvd_title_number, track_filename
#ffmpeg -i test.mp4 -ss 00:01:14.35 -vframes 1 out2.png

   jpg_start_time = "0:15"

   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{DVD_AUDIO_TMP_FILENAME}\" -ss #{jpg_start_time} -vframes 1 \"#{track_filename}.jpg\""

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for Track #{file_index} ...\n"
   system "#{conv_command}\n"
   
end

def extract_jpg_thumbnails tmp_vob_filename

   system "mkdir #{tmp_vob_filename}.images"
   
   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" #{FFMPEG_HDACCEL} -i #{tmp_vob_filename} -vf \"scale=720:576,yadif,fps=1/60\"  \"#{tmp_vob_filename}.images\\img%03d.png\" "

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for DVD ...\n"
   system "#{conv_command}\n"
   
end

def extract_full_vob_file dvd_drive,tmp_vob_filename

	system "\"#{DD_PATH}dd\" bs=2048 skip=15888 count=2282000 if=\\\\.\\#{dvd_drive} > \"#{tmp_vob_filename}\""

end

def convert_chapter start_time,end_time,file_index, tmp_vob_filename
	date=  "2006"
	genre= "HipHop"
	album= "Martelos"

   
   metadata = "-metadata title=\"Track #{file_index}\" -metadata artist=\"Pedro\" -metadata genre=\"#{genre}\" -metadata date=\"#{date}\" -metadata album=\"#{album}\" -metadata track=\"#{file_index}\""
   
   #conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\"  -i \"#{TARGET_FILENAME}\" -ss #{start_time} -to #{end_time} #{codec_options}  #{metadata} \"#{TARGET_FILENAME}\".split.#{file_index}.#{TARGET_FORMAT}"
   puts "conv #{start_time} .. #{end_time} \n"

   #Deinterlace to 50 fps
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}\" -ss #{start_time} -to #{end_time} -vf \"scale=720:576,yadif=1:-1:0\" -c:v mpeg2video -b:v 6000k -target pal-dvd -af \"pan=1c|c0=c0\" #{metadata} \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\""
  
   #Get motion vectors
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\" -vf \"vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transform_vectors2.trf\" -f null -"

   #Stabilize using the motion vectors      
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\" -vf \"vidstabtransform=input=transform_vectors2.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4, fps=25\" -c:v mpeg2video -b:v 6000k -target pal-dvd -acodec copy #{metadata} \"#{tmp_vob_filename}.yadif.deshaker.chapter#{file_index}.mpg\""
end

# TODO: automate dependencies and directories (currently hardcoded)

FFMPEG_PATH="D:\\Program Files\\ffmpeg-20161210\\bin\\"
FFMPEG_HDACCEL="-hwaccel dxva2 -threads 1"
#HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"

DVD_PATH="F:"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"

time = Time.now.getutc
time2 = time.to_s.delete ': '

time2 = "tmpdvd"

TARGET_PATH="G:\\temp\\dvd_extract_and_stabilize\\dvd.#{time2}"

tmp_vob_filename = "#{TARGET_PATH}\\dvd_full.vob"
tmp_vectors_filename = "#{TARGET_PATH}\\transform_vectors.trf"
target_video_filename = "#{TARGET_PATH}\\dvd_full.mp4"

print "mkdir \"#{TARGET_PATH}\""
system "mkdir \"#{TARGET_PATH}\""

PAUSE=false


puts "\ndvd_extract_and_stabilize.rb - Extract video from unfinalized DVD-VR or regular DVD-Video"
puts "-------------------------------------------------------------------------\n\n"
puts "Reading DVD structure ...\n\n"

extract_full_vob_file DVD_PATH, tmp_vob_filename
extract_jpg_thumbnails tmp_vob_filename

chapter = 1
chapter_duration = 60 * 10 

while chapter < 20 do

	chapter_start_time = (chapter-1) * chapter_duration
	chapter_end_time = (chapter) * chapter_duration
	
	convert_chapter chapter_start_time,chapter_end_time,chapter, tmp_vob_filename

	chapter = chapter + 1
end

