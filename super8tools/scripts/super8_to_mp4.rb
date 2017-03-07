#
# super8_to_mp4.rb
#
#


def convert_chapter start_time,end_time,file_index
	artist="Amy Winehouse"
	album= "Back to Black"
	date=  "2006"
	genre= "R&B"

   #start_time = start_time - 0.25
   #end_time = end_time + 0.25

   if TARGET_FORMAT.eql? "mp3"
		codec_options = "-codec:a libmp3lame -qscale:a 2"
   else
		codec_options = ""
   end
   
   #metadata = "-metadata title=\"Track #{file_index}\" -metadata artist=\"#{artist}\" -metadata genre=\"#{genre}\" -metadata date=\"#{date}\" -metadata album=\"#{album}\" -metadata track=\"#{file_index}\""
   metadata = "-metadata title=\"Track #{file_index}\" -metadata track=\"#{file_index}\""
   #MP3 conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\"  -i \"#{TARGET_FILENAME}\" -ss #{start_time} -to #{end_time} -codec:a libmp3lame -qscale:a 2 #{metadata} \"#{TARGET_FILENAME}\".split.#{file_index}.#{TARGET_FORMAT}"
   conv_command = "\"#{FFMPEG_PATH}ffmpeg.exe\"  -i \"#{TARGET_FILENAME}\" -ss #{start_time} -to #{end_time} #{codec_options}  #{metadata} \"#{TARGET_FILENAME}\".split.#{file_index}.#{TARGET_FORMAT}"
   #puts "conv #{start_time} .. #{end_time} \n"
   puts "#{conv_command}\n"
   puts "Running conversion...\n"
   system "#{conv_command}\n"
end

FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
TARGET_PATH="G:.\\"
TARGET_FILENAME=ARGV[0]
TARGET_FORMAT="mp4"


#PREVIEW=true
PREVIEW=false

puts "super8_to_mp4.rb - ..."
puts "-------------\n\n"

FILTERS="-vf \"dejudder,fps=25,fieldmatch=order=bff:combmatch=full, yadif=deint=interlaced,decimate,curves=preset=strong_contrast\" -aspect 16:9 -pix_fmt yuv420p"


system "\"#{FFMPEG_PATH}ffmpeg.exe\" -i \"#{TARGET_FILENAME}\"  #{FILTERS} \"#{TARGET_FILENAME}.super8.mp4\""

