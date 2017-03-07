#
#   super8_to_mp4.rb
#   ================
#   Converts a Super8 telecined video file to an MP4 output format with suitable filters for Super telecine
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


def convert_chapter start_time,end_time,file_index
	artist="DJ Estaline"
	album= "Martelos"
	date=  "2006"
	genre= "HipHop"

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

# TODO: automate dependencies and directories (currently hardcoded)
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

