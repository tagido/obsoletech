#
#   dvd_vr_grow_udf_and_finalize.rb
#   =======================
#   - burns a recovered ISO (or a new ISO) over an unfinalized DVD (DVD+VR or DVD-Video Recordable)
#   - can be used either for DVD+VR recovery  (with an ISO recovered by "dvd_vr_extract_files.rb")
#     or 
#   - for unfinalized DVD+VR recycling with another unrelated ISO 
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



DVD_VR_FIRST_TRACK_SIZE = 15872 # 2KB blocks

DVD_VIDEO_R_FIRST_TRACK_SIZE = 12272 # 2KB blocks

#DVD_VIDEO_R_FIRST_TRACK_SIZE = 1520 # 2KB blocks
# Este parece que finaliza a sessão quando grava a primeira pista, o que obriga a reler o "next_write_address" após a primeira pista
# TDK:
# MBI 01RG40
#
# c/ Verbatims antigos parece não funcionar

def get_DVD_MediaInfo_Full

	result = system "\"#{DVD_MEDIA_INFO_PATH}dvd+rw-mediainfo.exe\" \\\\.\\e: > #{TARGET_PATH}\\dvd_info.media_info.txt"

	if ( result == false) 
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
	mediainfo.track_size =         stats_raw.scan(/Track Size:( +)?([0-9]+)?(\*2KB)/)
	
	print "\n\nN_sessions = #{mediainfo.n_sessions}\n"
	print "disc status = #{mediainfo.disc_status}\n"
	print "No. of tracks = #{mediainfo.n_tracks}\n"
	print "  tracks tatus = #{mediainfo.track_status}\n"
	print "  next_write_address = #{mediainfo.next_write_address}\n"
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
		mediainfo.first_track_size = DVD_VR_FIRST_TRACK_SIZE
	else
		mediainfo.is_dvd_vr = false
	end
	
	# Check if it a DVD-VIDEO-R
	if ( (mediainfo.n_sessions.to_i() == 1) and (mediainfo.n_tracks.to_i() > 1) and (mediainfo.track_size[0][1].to_i() == DVD_VIDEO_R_FIRST_TRACK_SIZE))
		mediainfo.is_dvd_video_r = true
		mediainfo.first_track_size = DVD_VIDEO_R_FIRST_TRACK_SIZE
	else
		mediainfo.is_dvd_video_r = false
	end
	
	# Check if it is finalized
	if ( (mediainfo.disc_status == "appendable") )
		mediainfo.is_finalized = false
	else
		mediainfo.is_finalized = true
	end
	
	print "  finalized = #{mediainfo.is_finalized}\n"
	print "  dvd+vr ?  = #{mediainfo.is_dvd_vr}\n"
	print "  dvd-video-r ?  = #{mediainfo.is_dvd_video_r}\n"
	print "  first_track_size = #{mediainfo.first_track_size} blocks\n"
	
	return mediainfo
 
end



def extract_raw_data_from_track2


   dvd_stream_command = "\"#{DD_PATH}dd.exe\" bs=2048 skip=15888 if=\\\\.\\#{DVD_PATH}"
   
   conv_command = dvd_stream_command + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""

   puts "#{conv_command}\n"
   puts "Running RAW extraction for DVD ...\n"
   system "#{conv_command}\n"
   
end

def log_start_dump_dvd_file name, extension, index
	target_dir = "DVD_FILES"
	file_name = "#{target_dir}\\#{name}.#{index}.#{extension}"
	print "[Dumping] #{file_name} ...\n"
end

def dump_dvd_file name, extension, index, binary_contents

	target_dir = "DVD_FILES"

	file_name = "#{target_dir}\\#{name}.#{index}.#{extension}"

	open(file_name, 'ab') do |f|
		f.write(binary_contents)
	end

end

def cut_iso iso_path, cut_block_address, cut_iso_path
   
   # ex: "d:\Downloads\dd-0.6beta3\dd.exe" bs=2k if=Goa2013.iso skip=15920 of=GoaCut.iso
   
   system "del #{cut_iso_path}"
   
   dvd_cut_command = "\"#{DD_PATH}dd.exe\" bs=2k if=#{iso_path} skip=#{cut_block_address} of=#{cut_iso_path}"
   
   conv_command = dvd_cut_command # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""

   puts "#{conv_command}\n"
   puts "== Cutting source ISO ...\n"
   system "#{conv_command}\n"
end

def burn_dvd_track
end

def burn_first_dvd_vr_track iso_path, dvd_path, first_track_size

# eg.: "d:\Downloads\dd-0.6beta3\growisofs.exe" -use-the-force-luke=tracksize=15872 -Z e:=Beja97.iso
	
	dvd_dryrun_burn_command = "\"#{GROWISO_PATH}\" -dry-run -use-the-force-luke=tracksize=#{first_track_size} -Z #{dvd_path}=\"#{iso_path}\""
	
	dvd_burn_command = "\"#{GROWISO_PATH}\" -use-the-force-luke=tracksize=#{first_track_size} -Z #{dvd_path}=\"#{iso_path}\""

	conv_command = dvd_dryrun_burn_command # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""

    puts "#{conv_command}\n"
    puts "(*)== Burning first track (simulation) ...\n"
    system "#{conv_command}\n"

	wait_for_spacebar	
	
	conv_command = dvd_burn_command # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""

    puts "#{conv_command}\n"
    puts "(*)== Burning first track...\n"
    system "#{conv_command}\n"

	wait_for_spacebar

	puts "(?)== Checking DVD track status ...\n"
	get_DVD_MediaInfo_Full
	
end

def burn_second_dvd_vr_track cut_iso_path, second_track_next_write_address, dvd_path
# ex: "growisofs.exe" -dry-run -use-the-force-luke=seek:15920 -Z e:=Beja97Cut.iso
# -dvd-compat ?

	dvd_dryrun_burn_command = "\"#{GROWISO_PATH}\" -dvd-compat -dry-run -use-the-force-luke=seek:#{second_track_next_write_address} -Z #{dvd_path}=\"#{cut_iso_path}\""
	
	dvd_burn_command = "\"#{GROWISO_PATH}\" -dvd-compat -use-the-force-luke=seek:#{second_track_next_write_address} -Z #{dvd_path}=\"#{cut_iso_path}\""

	conv_command = dvd_dryrun_burn_command # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""


	
    puts "#{conv_command}\n"
    puts "(*)== Burning 2nd track (simulation) ...\n"
    system "#{conv_command}\n"

	wait_for_spacebar	
	
	conv_command = dvd_burn_command # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""

    puts "#{conv_command}\n"
    puts "(*)== Burning 2nd track...\n"
    system "#{conv_command}\n"

	wait_for_spacebar
	
	puts "(?)== Checking DVD track status ...\n"
	mediainfo = get_DVD_MediaInfo_Full
	
	
	next_write_address = mediainfo.next_write_address[0][1]
	track_size = 2282000
	
	#print "second=*#{second_track_next_write_address}*\n"
	
	dummy_filsesize = track_size * 2048
	
	puts "(*)== Finalizing DVD & track : burning the whole track from sector #{next_write_address} to #{track_size}...\n"
	
	system "del \"#{cut_iso_path}.dummy.raw\""
	system "fsutil file createnew \"#{cut_iso_path}.dummy.raw\" #{dummy_filsesize}"
	dvd_burn_command_final = "\"#{GROWISO_PATH}\" -dvd-compat -use-the-force-luke=seek:#{next_write_address} -Z #{dvd_path}=\"#{cut_iso_path}.dummy.raw\""
	print "dvd_burn_command=#{dvd_burn_command_final}\n"
	
	conv_command = dvd_burn_command_final # + "> #{TARGET_PATH}\\dvd_vr.busto.raw\""
	system "#{conv_command}\n"
	
	system "del \"#{cut_iso_path}.dummy.raw\""
	
	wait_for_spacebar
	puts "(?)== Checking DVD track status ...\n"
	mediainfo = get_DVD_MediaInfo_Full	
	

#TODO: finalizar (escrever até ao fim da pista) e testar se ficou finalizado

end

def grow_udf_and_finalize iso_path, iso_size, mediainfo

	if ( (mediainfo.is_dvd_vr or mediainfo.is_dvd_video_r)  and not mediainfo.is_finalized)

	
		first_track_size = mediainfo.first_track_size
		first_track_next_write_address = mediainfo.next_write_address[0][1].to_i()

if true			
		second_track_size = mediainfo.track_size[1][1].to_i()
		second_track_next_write_address = mediainfo.next_write_address[1][1].to_i()
else
	# TODO: For DVD-Video reread dvd media_info after the first track is written
	second_track_size = mediainfo.track_size[0][1].to_i()
	second_track_next_write_address = mediainfo.next_write_address[0][1].to_i()
end


		# sanity checks
		if first_track_next_write_address != 0 
			print "First track does not start at address 0, aborting ...\n"
			return
		end
		
		if first_track_size > iso_size 
			print "ISO size smaller than first track, aborting ...\n"
			return
		end

		
		# TODO: add more sanity checks
		#         warn when 2nd track already has too much data
		
		cut_iso iso_path, second_track_next_write_address, CUT_ISO_PATH
		
		burn_first_dvd_vr_track iso_path, DVD_PATH, first_track_size
		
		burn_second_dvd_vr_track CUT_ISO_PATH, second_track_next_write_address, DVD_PATH
		
	end

end

# TODO: automate dependencies and directories (currently hardcoded)
FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
GROWISO_PATH="#{DD_PATH}growisofs.exe"

DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"

DVD_PATH="e:"

#ISO_PATH="G:\\TEMP\\dvd_extract_and_stabilize\\RestauroHi8\\EUA92-04.iso"
ISO_PATH="G:\\temp\\dvd_info\\dvd_vr.files.NatGeo1\\FIXED_DVD_IMAGES\\ISO\\FixedDVD.iso"

time = Time.now.getutc
time2 = time.to_s.delete ': '


#TARGET_PATH="G:\\temp\\dvd_info\\dvd_vr.files.#{time2}"

TARGET_PATH="G:\\temp\\dvd_info\\dvd_vr.files\\tmp"
CUT_ISO_PATH="#{TARGET_PATH}\\DVDSecondHalf.Cut.raw"

print "mkdir \"#{TARGET_PATH}\""
system "mkdir \"#{TARGET_PATH}\""

PAUSE=false

puts "dvd_vr_grow_udf_and_finalize.rb - Gets info from unfinalized DVDs and merges a new ISO into it\n"
puts "-------------\n\n"
puts "Reading DVD structure ...\n\n"

mediainfo = get_DVD_MediaInfo_Full

if (mediainfo != nil)

	if (mediainfo.finalized)
		print("Current DVD is already finalized, nothing to to, exiting ...\n")
		exit
	end

	iso_size = File.stat("#{ISO_PATH}").size    
	
	if iso_size <= 0
		print("Invalid ISO file, exiting ...\n")
		exit
	end
	
	print("Source ISO properties:\n")
	print("== Path=#{ISO_PATH}\n")
	print("== Size=#{iso_size} Bytes / #{iso_size/1024/1024} MB\n")

	grow_udf_and_finalize ISO_PATH, iso_size, mediainfo
	
end


# TODO: ver automaticamente se é um DVD+VR não finalizado
# TODO: mostrar espaço livre e ocupado
# TODO: mostrar tempo estimado de vídeo no DVD
