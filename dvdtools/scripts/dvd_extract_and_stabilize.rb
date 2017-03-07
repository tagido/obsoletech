#
# dvd_extract_and_stabilize.rb
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

def extract_jpg_thumbnails tmp_vob_filename
#ffmpeg -i test.mp4 -ss 00:01:14.35 -vframes 1 out2.png

   #system "del #{TARGET_PATH}*.png"

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
	genre= "R&B"
	album= "EUA92"

   #start_time = start_time - 0.25
   #end_time = end_time + 0.25
   
   metadata = "-metadata title=\"Track #{file_index}\" -metadata artist=\"Pedro\" -metadata genre=\"#{genre}\" -metadata date=\"#{date}\" -metadata album=\"#{album}\" -metadata track=\"#{file_index}\""
   #metadata = "-metadata title=\"#{track_name}\" -metadata track=\"#{file_index}\""
   
   #conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\"  -i \"#{TARGET_FILENAME}\" -ss #{start_time} -to #{end_time} #{codec_options}  #{metadata} \"#{TARGET_FILENAME}\".split.#{file_index}.#{TARGET_FORMAT}"
   puts "conv #{start_time} .. #{end_time} \n"

if file_index > 1
   #Deinterlace to 50 fps
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}\" -ss #{start_time} -to #{end_time} -vf \"scale=720:576,yadif=1:-1:0\" -c:v mpeg2video -b:v 6000k -target pal-dvd -af \"pan=1c|c0=c0\" #{metadata} \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\""
  
   #Get motion vectors
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\" -vf \"vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transform_vectors2.trf\" -f null -"
end

   #Stabilize using the motion vectors   
   #system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\" -vf \"vidstabtransform=input=transform_vectors2.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4, fps=25\" -vcodec libx264 -preset slow -tune film -crf 18 -acodec copy #{metadata} \"#{tmp_vob_filename}.yadif.deshaker.chapter#{file_index}.mp4\""
   system "\"#{FFMPEG_PATH}ffmpeg\" #{FFMPEG_HDACCEL} -i \"#{tmp_vob_filename}.yadif.chapter#{file_index}.mpg\" -vf \"vidstabtransform=input=transform_vectors2.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4, fps=25\" -c:v mpeg2video -b:v 6000k -target pal-dvd -acodec copy #{metadata} \"#{tmp_vob_filename}.yadif.deshaker.chapter#{file_index}.mpg\""
end

#FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
FFMPEG_PATH="D:\\Program Files\\ffmpeg-20161210\\bin\\"
FFMPEG_HDACCEL="-hwaccel dxva2 -threads 1"
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"

DVD_PATH="E:"

#DVD_PATH="\"H:\\DVDs Musicais\\Tony Carreira\\\""
#DVD_PATH="\"H:\\DVDs Musicais\\FengShui\\\""
#DVD_PATH="H:.\\"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"
#DVD_VOB_CONCAT_LIST="#{DVD_VOB_PATH}VTS_01_0.VOB\|#{DVD_VOB_PATH}VTS_01_1.VOB\|#{DVD_VOB_PATH}VTS_01_2.VOB\|#{DVD_VOB_PATH}VTS_01_3.VOB\|#{DVD_VOB_PATH}VTS_01_4.VOB"

time = Time.now.getutc
time2 = time.to_s.delete ': '

time2 = "001B2AltoDosLombos_95_Beja_Incenso_EUA92"

TARGET_PATH="G:\\temp\\dvd_extract_and_stabilize\\dvd.#{time2}"

tmp_vob_filename = "#{TARGET_PATH}\\dvd_full.vob"
tmp_vectors_filename = "#{TARGET_PATH}\\transform_vectors.trf"
target_video_filename = "#{TARGET_PATH}\\dvd_full.mp4"

print "mkdir \"#{TARGET_PATH}\""

system "mkdir \"#{TARGET_PATH}\""


PAUSE=false


puts "\ndvd_extract_and_stabilize.rb - Extract video from unfinalized DVD-VR or regular DVD-Video"
puts "-------------\n\n"
puts "Reading DVD structure ...\n\n"

#get_VOB_file_names

#get_No_of_DVD_titles

#get_DVD_MediaInfo
#extract_jpg_thumbnails 

#extract_full_vob_file DVD_PATH, tmp_vob_filename
#extract_jpg_thumbnails tmp_vob_filename

#Deinterlace to 50 fps
#system "\"#{FFMPEG_PATH}ffmpeg\" -i \"#{tmp_vob_filename}\" -vf \"yadif=1:-1:0\" \"#{tmp_vob_filename}.yadif.mp4\""

# Partir em bocados de 10 minutos (?)
# ... gerar os desentrelaçados já partidos em vários ficheiros

#Get motion vectors
#	system "\"#{FFMPEG_PATH}ffmpeg\" -i \"#{tmp_vob_filename}.yadif.mp4\" -vf \"vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transform_vectors.trf\" -f null -"

#Stabilize using the motion vectors
#	system "\"#{FFMPEG_PATH}ffmpeg\" -loglevel debug -i \"#{tmp_vob_filename}.yadif.mp4\" -vf \"vidstabtransform=input=transform_vectors.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4\" -vcodec libx264 -preset slow -tune film -crf 18 -acodec copy \"#{target_video_filename}\""


chapter = 1
chapter_duration = 60 * 10 

while chapter < 20 do

	chapter_start_time = (chapter-1) * chapter_duration
	chapter_end_time = (chapter) * chapter_duration
	
	convert_chapter chapter_start_time,chapter_end_time,chapter, tmp_vob_filename

	chapter = chapter + 1
end



#system "\"#{FFMPEG_PATH}ffmpeg\" -loglevel debug -i \"#{tmp_vob_filename}.yadif.mp4\" -ss 00:00:00 -to 00:02:00 -vf \"vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transform_vectors2.trf\" -f null -"
#system "\"#{FFMPEG_PATH}ffmpeg\" -i \"#{tmp_vob_filename}.yadif.mp4\" -ss 00:00:00 -to 00:02:00 -vf \"vidstabtransform=input=transform_vectors2.trf:zoom=1:smoothing=30,unsharp=5:5:0.8:3:3:0.4\" -vcodec libx264 -preset slow -tune film -crf 18 -acodec copy \"#{target_video_filename}\""

#system "\"#{FFMPEG_PATH}ffmpeg\" -i \"#{tmp_vob_filename}\" -vf \"vidstabtransform=input=transform_vectors.trf\" \"#{target_video_filename}\""
