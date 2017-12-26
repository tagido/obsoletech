#
#   dvd_info.rb
#   ===================
#   Gets media information and video thumbnails from 
#   a finalized DVD-Video or an a unfinalized DVD+VR
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

require 'ostruct'
require_relative "../../../zerosociety/framework/scripts/framework_utils.rb"
require_relative "dvd_common_utils.rb"



def get_DVD_MediaInfo

	#result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"
	
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


def extract_chapter_jpg_thumbnail start_time, file_index, dvd_title_number, track_filename
#ffmpeg -i test.mp4 -ss 00:01:14.35 -vframes 1 out2.png

   jpg_start_time = "0:15"

   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{DVD_AUDIO_TMP_FILENAME}\" -ss #{jpg_start_time} -vframes 1 \"#{track_filename}.jpg\""

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for Track #{file_index} ...\n"
   system "#{conv_command}\n"
   
end

def extract_jpg_thumbnails 
#ffmpeg -i test.mp4 -ss 00:01:14.35 -vframes 1 out2.png

   #system "del #{TARGET_PATH}*.png"

   # TODO: determinar automaticamente início da 2ª pista
   
   #start_sector = 15888
   #start_sector = 13344
   #start_sector = 0
   #start_sector = 1808
   start_sector = 13584
   
   #fps="1/60"
   fps="1/2"
   
   dvd_stream_command = "\"#{DD_PATH}dd.exe\" bs=2048 skip=#{start_sector} if=\\\\.\\#{DVD_DRIVE}"
   
   conv_command = dvd_stream_command + "|" + "\"#{FFMPEG_PATH}ffmpeg.exe\" -i - -vf \"yadif,fps=#{fps}\"  \"#{TARGET_PATH}\\img%03d.png\" 2> \"#{TARGET_PATH}\\dvd_info.ffmpeg_thumbnails.txt\""

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for DVD ...\n"
   system "#{conv_command}\n"
   
end


FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
#HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_DRIVE="E:"
DVD_PATH="#{DVD_DRIVE}\\"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"

time = Time.now.getutc
time2 = time.to_s.delete ': '

TARGET_PATH="G:\\temp\\dvd_info\\dvd_info.report.#{time2}"

print "mkdir \"#{TARGET_PATH}\""

system "mkdir \"#{TARGET_PATH}\""


TARGET_FILENAME="DVD - Track "
DVD_AUDIO_TMP_FILENAME="#{TARGET_PATH}dvd_full_audio.mpg"
DVD_RAW_FILENAME="#{TARGET_PATH}\\dvd_recovered.raw"
DVD_AUDIO_STREAM_INDEX="4"
DVD_TITLE_INDEX=6
DVD_LAST_TITLE_TO_PROCESS=6
#Obsoleto: DVD_VTS_INDEX=2

PAUSE=false


puts "dvd_info.rb - Gets info from unfinalized DVDs"
puts "-------------\n\n"
puts "Reading DVD structure ...\n\n"


dvd_info=get_DVD_MediaInfo_extended
extract_jpg_thumbnails 

if ARGV[0]=="extractraw"

	dvd_report_init "#{DVD_RAW_FILENAME}.log"

	extract_raw_data_from_dvd_sector_to_the_end dvd_info.track_start_address[dvd_info.n_tracks.to_i-1][1], DVD_RAW_FILENAME	, DVD_DRIVE
end

# TODO: ver automaticamente se é um DVD-VR não finalizado
# TODO: mostrar espaço livre e ocupado
# TODO: mostrar tempo estimado de vídeo no DVD
# TODO: procurar pelas imagens no google imagens
# TODO: concatenar relatório num HTML