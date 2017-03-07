#
# dvd_info.rb
#
#
require 'ostruct'

origin = OpenStruct.new
origin.x = 0
origin.y = 0

# Wait for the spacebar key to be pressed
def wait_for_spacebar
   print "Press space to continue ...\n"
   sleep 1 while $stdin.getc != " "
end

def get_No_of_DVD_titles


result = system "\"#{HANDBRAKECLI_PATH}HandBrakeCLI.exe\" --scan -t 0 -i #{DVD_PATH} 2> dvd_chapters.all_titles.handbrake.txt"

if (result == false) 
  print "#### Could not read DVD structure, exiting ... \n"
  exit
end

stats_raw = `type dvd_chapters.all_titles.handbrake.txt`

print stats_raw

# ex: [20:05:39] scan: DVD has 3 title(s)

n_titles = stats_raw.scan(/DVD has ([0-9]+) title/)

print "n_titles=#{n_titles[0][0]}\n"

end

def get_DVD_MediaInfo

	#result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"
	
	result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"

	if (result == false) 
		print "#### Could not read DVD structure, exiting ... \n"
	#	exit
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


def conv_hhmmss_to_seconds time_string

 seconds = "#{time_string}".split(':').map { |a| a.to_i }.inject(0) { |a, b| a * 60 + b}

 return seconds
 
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
   
   start_sector = 15888
   #start_sector = 13344
   #start_sector = 0
   #start_sector = 1808
   
   dvd_stream_command = "\"#{DD_PATH}dd.exe\" bs=2048 skip=#{start_sector} if=\\\\.\\#{DVD_DRIVE}"
   
   conv_command = dvd_stream_command + "|" + "\"#{FFMPEG_PATH}ffmpeg.exe\" -i - -vf \"yadif,fps=1/60\"  \"#{TARGET_PATH}\\img%03d.png\" 2> \"#{TARGET_PATH}\\dvd_info.ffmpeg_thumbnails.txt\""

   puts "#{conv_command}\n"
   puts "Running thumbnail extraction for DVD ...\n"
   system "#{conv_command}\n"
   
end


FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_DRIVE="E:"
DVD_PATH="#{DVD_DRIVE}\\"

#DVD_PATH="\"H:\\DVDs Musicais\\Tony Carreira\\\""
#DVD_PATH="\"H:\\DVDs Musicais\\FengShui\\\""
#DVD_PATH="H:.\\"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"
#DVD_VOB_CONCAT_LIST="#{DVD_VOB_PATH}VTS_01_0.VOB\|#{DVD_VOB_PATH}VTS_01_1.VOB\|#{DVD_VOB_PATH}VTS_01_2.VOB\|#{DVD_VOB_PATH}VTS_01_3.VOB\|#{DVD_VOB_PATH}VTS_01_4.VOB"

time = Time.now.getutc
time2 = time.to_s.delete ': '

TARGET_PATH="G:\\temp\\dvd_info\\dvd_info.report.#{time2}"

print "mkdir \"#{TARGET_PATH}\""

system "mkdir \"#{TARGET_PATH}\""


TARGET_FILENAME="DVD - Track "
DVD_AUDIO_TMP_FILENAME="#{TARGET_PATH}dvd_full_audio.mpg"
DVD_AUDIO_STREAM_INDEX="4"
DVD_TITLE_INDEX=6
DVD_LAST_TITLE_TO_PROCESS=6
#Obsoleto: DVD_VTS_INDEX=2

PAUSE=false


puts "dvd_info.rb - Gets info from unfinalized DVDs"
puts "-------------\n\n"
puts "Reading DVD structure ...\n\n"

#get_VOB_file_names

#get_No_of_DVD_titles

#for i in DVD_TITLE_INDEX..DVD_LAST_TITLE_TO_PROCESS
#   puts "Processing DVD Title #{i}"
#   convert_dvd_title i
#end

get_DVD_MediaInfo
extract_jpg_thumbnails 

# TODO: ver automaticamente se é um DVD-VR não finalizado
# TODO: mostrar espaço livre e ocupado
# TODO: mostrar tempo estimado de vídeo no DVD
# TODO: procurar pelas imagens no google imagens
# TODO: concatenar relatório num HTML