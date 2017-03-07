#
#   dvd_vr_extract_files.rb 
#   =======================
#   - Extracts info and video from unfinalized DVDs (DVD+VR or DVD-Video Recordable)
#   - Builds an ISO with the original DVD layout plus needed features like missing menus and missing UDF file system
#   - Previews the recovered ISO with VLC
#   - TODO: burn the recovered ISO over the original DVD 
#       (workaround: call dvd_vr_grow_udf_and_finalize.rb manually, 
#        after the recovered ISO is working fine)
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

origin = OpenStruct.new
origin.x = 0
origin.y = 0

# Wait for the spacebar key to be pressed
def wait_for_spacebar
   print "Press space to continue ...\n"
   sleep 1 while $stdin.getc != " "
end


def dvd_report_create_log_file
   File.open(REPORT_FILE, 'w') { |file| file.write("#############################################\n") }
end


def dvd_report_print string
   File.open(REPORT_FILE, 'a') { |file| file.write(string) }
   print string
end

def dvd_report_print_section_break
    vmhost_report_print "\n---X---X---X---X---X---X---X---X---X---\n\n"
end

def dvd_report_system_return_output command
   system "#{command} > #{TMP_STDOUT_FILE} 2> #{TMP_STDERR_FILE}"
   
   output1 = `copy #{TMP_STDOUT_FILE}+#{TMP_STDERR_FILE} #{TMP_STDERR_AND_STDOUT_FILE}` 
   
   output = `type #{TMP_STDERR_AND_STDOUT_FILE}`
   
   #system "cat #{TMP_STDOUT_FILE} #{TMP_STDERR_FILE} >> #{REPORT_FILE}"
   
   dvd_report_print "#{output}"
   
   return output
end


DVD_VR_FIRST_TRACK_SIZE = 15872 # 2KB blocks


def get_DVD_MediaInfo

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
	mediainfo.track_size =         stats_raw.scan(/Track Size:( +)?([0-9]+)?(\*2KB)/)
	
	print "\n\nN_sessions = #{mediainfo.n_sessions}\n"
	print "disc status = #{mediainfo.disc_status}\n"
	print "No. of tracks = #{mediainfo.n_tracks}\n"
	print "  tracks status = #{mediainfo.track_status}\n"
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


def conv_hhmmss_to_seconds time_string

 seconds = "#{time_string}".split(':').map { |a| a.to_i }.inject(0) { |a, b| a * 60 + b}

 return seconds
 
end


def extract_raw_data_from_track2


   dvd_stream_command = "\"#{DD_PATH}dd.exe\" bs=2048 skip=15888 if=\\\\.\\#{DVD_PATH}"
   
   conv_command = dvd_stream_command + "> #{RECOVERED_RAW_FILE}"

   puts "#{conv_command}\n"
   dvd_report_print "(+)== Running RAW extraction for DVD ... extracting to #{RECOVERED_RAW_FILE}\n"
   system "#{conv_command}\n"
   
end

def log_start_dump_dvd_file name, extension, index
	target_dir = "#{RECOVERED_FILES_PATH}"
	file_name = "#{target_dir}\\#{name}.#{index}.#{extension}"
	dvd_report_print "(+)== [Dumping] #{file_name} ...\n"
end

def dump_dvd_file name, extension, index, binary_contents

	target_dir = "#{RECOVERED_FILES_PATH}"

	file_name = "#{target_dir}\\#{name}.#{index}.#{extension}"

	open(file_name, 'ab') do |f|
		f.write(binary_contents)
	end

end

DUMP_IFO_FILES = true
DUMP_VOB_FILES = false

def extract_files_from_raw_data


	current_block_index = 15888

	prev_found_sig_block_index = 0
	
	current_vts_index = 1
	current_vts_vob_index = 1
	current_video_ifo_index = 1
	
	first_vob_block_printed = false
	
	prev_block_was_NSR = false
	
	currently_inside_video = false
	currently_inside_video_ifo = false
	current_video_start_block = 0
	
	last_open_vob_found = false
	last_open_vob_start_sector = 0
	last_open_vob_end_sector = 0

	# Remove files from previous runs
	dvd_report_system_return_output "del \/Q #{RECOVERED_FILES_PATH}\\*.VOB"
	dvd_report_system_return_output "del \/Q #{RECOVERED_FILES_PATH}\\*.IFO"
	
    #open("#{TARGET_PATH}\\vob_block.raw", 'rb') do |f|
	open(RECOVERED_RAW_FILE, 'rb') do |f|
	
	#and current_block_index < 1000000
	  
	  while (block=f.read(2048) )
	  
		
			
		#r = Regexp.new("(\x00\x00\x01\xba|\x00\x00\x01\xbb|\x00\x00\x01\xb9|DVDVIDEO-VMG|DVDVIDEO-VTS|NSR02|DVDVRMANAGER|DVDAUTH-INFO)".force_encoding("binary"), Regexp::FIXEDENCODING)
		
		r = Regexp.new("(\x00\x00\x01\xba|DVDVIDEO-VMG|DVDVIDEO-VTS|NSR02|DVDVRMANAGER|DVDAUTH-INFO)".force_encoding("binary"), Regexp::FIXEDENCODING)
		
		signatures = block.scan( r )
		
		#puts "#{current_block_index}: #{current_block_index*2048}..#{(current_block_index+1)*2048}..  signatures=#{signatures}"
		
		if (!signatures.nil? and signatures.length>0 )
			#puts("Found signatures at block #{current_block_index}\n")
			#puts "#{current_block_index}: #{current_block_index*2048}..#{(current_block_index+1)*2048}..  signatures=#{signatures}"
			
			if (signatures[0][0] == "DVDVIDEO-VMG") or (signatures[0][0] == "DVDVIDEO-VTS") or (signatures[0][0] == "DVDVRMANAGER") or (signatures[0][0] == "NSR02") or (signatures[0][0] == "DVDAUTH-INFO")
				
				
				diff = (current_block_index - prev_found_sig_block_index) * 2
				dvd_report_print "... diff from previous #{diff} KB\n"
				
				dvd_report_print "#{current_block_index}: #{current_block_index*2048}..#{(current_block_index+1)*2048}..  signatures=#{signatures}"
			
				prev_found_sig_block_index = current_block_index
				first_vob_block_printed = false
				if currently_inside_video
					currently_inside_video = false
					current_vts_vob_index = current_vts_vob_index + 1
				end
				
				if (signatures[0][0] == "DVDVIDEO-VTS")
					inside_vts = true
					log_start_dump_dvd_file "VTS", "IFO", current_vts_index
				else if inside_vts
					inside_vts = false
					current_vts_index = current_vts_index + 1
					end
				end
				
				if (signatures[0][0] == "DVDVIDEO-VMG")
					if (currently_inside_video_ifo)
						current_video_ifo_index = current_video_ifo_index + 1
					else
						currently_inside_video_ifo = true
					end
					log_start_dump_dvd_file "VIDEO", "IFO", current_video_ifo_index
				else if currently_inside_video_ifo
					currently_inside_video_ifo = false
					current_video_ifo_index = current_video_ifo_index + 1
					end
				end
			
				if (signatures[0][0] == "NSR02")			
					prev_block_was_NSR = true
				else
					prev_block_was_NSR = false
				end
				
			else # VOB/MPEG2 block
				if ( !first_vob_block_printed and prev_block_was_NSR )
				  dvd_report_print "... first VOB block LBA: #{current_block_index-16384}  signatures=#{signatures}"
				  first_vob_block_printed = true
				  currently_inside_video = true
				  current_video_start_block = current_block_index
				  
				  log_start_dump_dvd_file "VTS_01", "VOB", current_vts_vob_index
				end		
			end
			
			
			
			##NSR02|DVDVRMANAGER|DVDAUTH-INFO"
			
			
			
		end

		if DUMP_IFO_FILES		
			if (inside_vts)
				dump_dvd_file "VTS","IFO",current_vts_index, block
			end
			
			if (currently_inside_video_ifo)
				dump_dvd_file "VIDEO","IFO",current_video_ifo_index, block
			end			
		end
		
		if DUMP_VOB_FILES
			if (currently_inside_video)
				if (current_vts_vob_index > 6) #TMP
					dump_dvd_file "VTS_01", "VOB", current_vts_vob_index, block
				end
			end
		end
		
		current_block_index = current_block_index + 1
	  end
	  
	  if (currently_inside_video)
		dvd_report_print "[OPEN Video Block] from LBA #{current_video_start_block-16384} to #{current_block_index-16384}\n"
		
		# TODO: subtituir por constantes
		last_open_vob_found = true
		last_open_vob_start_sector = current_video_start_block-16384
		last_open_vob_end_sector = current_block_index-16384
		
	  end
	  
	end

	dvdvr_recovered_filesystem_info = OpenStruct.new
	
	dvdvr_recovered_filesystem_info.n_vts_ifo_found = current_vts_index -1
	dvdvr_recovered_filesystem_info.n_video_ifo_found = current_video_ifo_index -1
	dvdvr_recovered_filesystem_info.n_vts_vobs = current_vts_vob_index -1
	dvdvr_recovered_filesystem_info.last_open_vob_found = last_open_vob_found
	dvdvr_recovered_filesystem_info.last_open_vob_start_sector = last_open_vob_start_sector
	dvdvr_recovered_filesystem_info.last_open_vob_end_sector = last_open_vob_end_sector

	dvd_report_print "#{dvdvr_recovered_filesystem_info}"

	return dvdvr_recovered_filesystem_info
end



def build_dvd_video_filesystem__copy_resource_files resource_files_path, target_files_path, dvdvr_recovered_filesystem_info
	dvd_report_print "(+)== Copying empty VTS VOB files\n"
	
	dvd_report_system_return_output "#{SEVENZIP_PATH} e \"#{RESOURCES_EMPTY_VOBS_ZIP}\" -y -o\"#{target_files_path}\\VIDEO_TS\""
	
	dvd_report_print "(+)== Copying good IFO and VOB files\n"
	
	dvd_report_system_return_output "#{SEVENZIP_PATH} e \"#{RESOURCES_GOOD_IFOS_VOBS_ZIP}\" -y -o\"#{target_files_path}\\VIDEO_TS\""

	# truncate -s 31696896 busto2/VIDEO_TS/VIDEO_TS.VOB
	#TODO: determinar o nº de bytes dinamicamente
	
	dvd_report_system_return_output "copy \"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB\" \"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB.bak\""
	dvd_report_system_return_output "del \"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB\""
	dvd_report_system_return_output "fsutil file createnew \"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB\" 31696896"
    dvd_report_system_return_output "\"#{DD_PATH}dd.exe\" of=\"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB\" if=\"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB.bak\""
	dvd_report_system_return_output "del \"#{target_files_path}\\VIDEO_TS\\VIDEO_TS.VOB.bak\""
	
end

def build_dvd_video_filesystem__copy_extracted_files extracted_files_path, target_files_path, dvdvr_recovered_filesystem_info
	dvd_report_print "(+)== Copying extracted RAW VOB data to the VOB files\n"
	
	# dd 1, 2, 4, 5 ...

	next_sector = 496
	
	vob_size_in_sectors = 1069547520 / 2048
	
	for i in 1..5 
	
		dvd_report_system_return_output "\"#{DD_PATH}dd.exe\" bs=2048 skip=#{next_sector} if=#{extracted_files_path}\\dvd_vr.recovered.raw of=#{target_files_path}\\VIDEO_TS\\VTS_01_#{i}.VOB count=#{vob_size_in_sectors}\n"
	
		next_sector = next_sector + vob_size_in_sectors
	end
	
	
	dvd_report_print "(+)== Copying extracted  VTS IFO data to the VOB files\n"
	
	last_extracted_vts_ifo_file = "VTS.#{dvdvr_recovered_filesystem_info.n_vts_ifo_found}.IFO"
	
	dvd_report_print "last extracted vts ifo file=#{last_extracted_vts_ifo_file}\n"

	#TODO: truncate -s 1142784 busto2/VIDEO_TS/VTS_01_0.IFO
	
	#TODO: determinar o nº de bytes dinamicamente
	
	dvd_report_system_return_output "del #{target_files_path}\\VIDEO_TS\\VTS_01_0.IFO"
	dvd_report_system_return_output "fsutil file createnew #{target_files_path}\\VIDEO_TS\\VTS_01_0.IFO 1196032"
	dvd_report_system_return_output "\"#{DD_PATH}dd.exe\" if=\"#{extracted_files_path}\\#{last_extracted_vts_ifo_file}\" of=\"#{target_files_path}\\VIDEO_TS\\VTS_01_0.IFO\""
	dvd_report_system_return_output "copy #{extracted_files_path}\\#{last_extracted_vts_ifo_file} #{target_files_path}\\VIDEO_TS\\VTS_01_0.BUP"
	
end


def build_dvd_video_filesystem__make_iso source_files_path, target_iso_path

	dvd_report_print "(+)== Making final ISO file\n"

	dvd_report_system_return_output "\"#{MKISOFS_PATH}\" -udf -volid OBSOLETECH_DVDVR -sort \"#{RESOURCES_ISO_SORT_FILE_PATH}\"  -o \"#{target_iso_path}\" \"#{source_files_path}\""

end


def build_dvd_video_filesystem__check_filesystem_VTS_VOB_files target_files_path

	# TODO:
	# Check if the VOB files fill the 4,7GB file system
	# Check if the VOB files break at the 1GB boundaries ( 1069547520 bytes )
	# Check if there is only one VTS


end

def build_dvd_video_filesystem__check_filesystem_files target_files_path
	dvd_report_print "(?)== Checking DVD Video filesystem consistency\n"
	
	dvd_report_system_return_output "dir /s #{target_files_path}"
	
	result = system "\"#{HANDBRAKECLI_PATH}HandBrakeCLI.exe\" -t 0 -i #{target_files_path}  2> #{TARGET_PATH}\\dvd.filesystem_info.txt"

	if (false and result == false) 
		print "#### Could not read DVD structure, exiting ... \n"
		return nil
	end	

	stats_raw = `type #{TARGET_PATH}\\dvd.filesystem_info.txt | find /V "src/nav_read.c:264" |find /V "ifo_read.c:1686" | find /V "c_adt->cell_adr_table[i].last_sector" | find /V "dsi->dsi_gi.zero1 == 0"`

	dvd_report_print stats_raw

	dvdfilesystem_info = OpenStruct.new
	
	dvdfilesystem_info.n_valid_titles = stats_raw.scan(/scan thread found ([0-9]+) valid title/)[0][0]
	
	#mediainfo.n_sessions =         stats_raw.scan(/Number of Sessions:    ([0-9]+)/)[0][0]
	#mediainfo.n_tracks =           stats_raw.scan(/Number of Tracks:      ([0-9]+)/)[0][0]
	#mediainfo.disc_status =        stats_raw.scan(/Disc status:           (.+)/)[0][0]
	#mediainfo.track_status =       stats_raw.scan(/Track State:           (.+)/)
	#mediainfo.free_blocks =        stats_raw.scan(/Free Blocks:( +)?([0-9]+)?(\*2KB)/)
	#mediainfo.next_write_address = stats_raw.scan(/Next Writable Address:( +)?([0-9]+)?(\*2KB)/)
	#mediainfo.track_size =         stats_raw.scan(/Track Size:( +)?([0-9]+)?(\*2KB)/)
	
	dvd_report_print "#{dvdfilesystem_info}"
	
	
	build_dvd_video_filesystem__check_filesystem_VTS_VOB_files target_files_path
	
end

def build_dvd_video_filesystem__check_filesystem_iso   target_iso_path
	
	puts "(?)== Checking DVD ISO consistency ...\n"
	
	puts "(?)==== Playing DVD ISO with VLC ... please check if it played correctly\n"

	dvd_report_system_return_output "#{VLC_PATH} dvd://#{target_iso_path}"
	
	wait_for_spacebar
end


def build_dvd_video_filesystem extracted_files_path, resource_files_path, target_files_path, target_iso_path, dvdvr_recovered_filesystem_info

	dvd_report_print "(+)== Building DVD Video filesystem\n"
	dvd_report_print "(+)== == Configuration:\n"
	dvd_report_print "(+)== ==   Merging #{extracted_files_path} and #{resource_files_path}\n"
	dvd_report_print "(+)== ==        to #{target_files_path} and #{target_iso_path}\n"

	build_dvd_video_filesystem__copy_resource_files resource_files_path, target_files_path, dvdvr_recovered_filesystem_info

	build_dvd_video_filesystem__copy_extracted_files extracted_files_path, target_files_path, dvdvr_recovered_filesystem_info
	
	#build_dvd_video_filesystem__fix_image_files target_files_path
	
	build_dvd_video_filesystem__check_filesystem_files target_files_path
	
	
	# ISO
	
	build_dvd_video_filesystem__make_iso target_files_path, target_iso_path
	build_dvd_video_filesystem__check_filesystem_iso   target_iso_path
	
end

# MPG, VOB DVD Video Movie File (video/dvd, video/mpeg) or DVD MPEG2
# 
# Header:
# 
# 00 00 01 BA 	  
# 
# Trailer:
# 00 00 01 B9 

# TODO: automate dependencies and directories (currently hardcoded)
FFMPEG_PATH="D:\\Program Files (x86)\\FFmpeg for Audacity\\"
HANDBRAKECLI_PATH="D:\\Program Files\\Handbrake\\"
DD_PATH="D:\\Downloads\\dd-0.6beta3\\"
SEVENZIP_PATH="\"c:\\Program Files\\7-Zip\\7z.exe\""
MKISOFS_PATH="\"D:\\Downloads\\dd-0.6beta3\\mkisofs.exe\""
VLC_PATH="\"C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe\""
DVD_MEDIA_INFO_PATH="D:\\Downloads\\dd-0.6beta3\\"

DVD_PATH="E:"

DVD_VOB_PATH="#{DVD_PATH}VIDEO_TS\\"

time = Time.now.getutc
time2 = time.to_s.delete ': '


#TARGET_PATH="G:\\temp\\dvd_info\\dvd_vr.files.#{time2}"

TARGET_PATH="G:\\temp\\dvd_info\\dvd_vr.files.Zorro"

puts "dvd_vr_extract_files.rb - Gets info from unfinalized DVDs\n"
puts "-------------\n\n"


REPORT_FILE="#{TARGET_PATH}\\dvr_vr_extract.log"
TMP_STDOUT_FILE = "#{REPORT_FILE}.tmp.stdout.log"
TMP_STDERR_FILE = "#{REPORT_FILE}.tmp.stderr.log"
TMP_STDERR_AND_STDOUT_FILE = "#{REPORT_FILE}.tmp.stderr_stdout.log"


RECOVERED_FILES_PATH="#{TARGET_PATH}\\DVD_FILES"
RECOVERED_RAW_FILE="#{RECOVERED_FILES_PATH}\\dvd_vr.recovered.raw"

dvd_report_create_log_file

# Build target tree
dvd_report_print "(+)== Building target tree ...\n\n"

dvd_report_print "== Command-line: #{ARGV}\n"
dvd_report_print "== Script directory: #{File.dirname(__FILE__)}\n"

RESOURCES_PATH="#{File.dirname(__FILE__)}\\resources\\DVD+VR"
RESOURCES_EMPTY_VOBS_ZIP="#{RESOURCES_PATH}\\EmptyVOBS\\EmptyVOBS.zip"
RESOURCES_GOOD_IFOS_VOBS_ZIP="#{RESOURCES_PATH}\\GoodIFOsAndVOBs\\GoodIFOsAndVOBs.zip"
RESOURCES_ISO_SORT_FILE_PATH="#{RESOURCES_PATH}\\mkiso.dvd_filesystem_sort.txt"

dvd_report_print "== Resources directory: #{RESOURCES_PATH}\n"

system "mkdir #{RECOVERED_FILES_PATH}"

FIXED_DVD_IMAGES_PATH="#{TARGET_PATH}\\FIXED_DVD_IMAGES"
FIXED_DVD_IMAGES_FILES_PATH="#{FIXED_DVD_IMAGES_PATH}\\SOURCE"
FIXED_DVD_IMAGES_ISO_PATH="#{FIXED_DVD_IMAGES_PATH}\\ISO"
FIXED_DVD_IMAGES_ISO_FILE="#{FIXED_DVD_IMAGES_ISO_PATH}\\FixedDVD.iso"

system "mkdir #{FIXED_DVD_IMAGES_PATH}"
system "mkdir #{FIXED_DVD_IMAGES_FILES_PATH}"
system "mkdir #{FIXED_DVD_IMAGES_ISO_PATH}"

print "mkdir \"#{TARGET_PATH}\""

system "mkdir \"#{TARGET_PATH}\""

PAUSE=false


dvd_report_print "(?)== Reading DVD structure ...\n\n"

mediainfo = get_DVD_MediaInfo

if (mediainfo.is_dvd_vr)
	#extract_raw_data_from_track2
	dvdvr_recovered_filesystem_info = extract_files_from_raw_data
	#dvdvr_recovered_filesystem_info = nil
	
	build_dvd_video_filesystem RECOVERED_FILES_PATH, RESOURCES_PATH, FIXED_DVD_IMAGES_FILES_PATH, FIXED_DVD_IMAGES_ISO_FILE, dvdvr_recovered_filesystem_info
else
	puts "(!)== No DVD+VR found ...\n\n"
end

# TODO: ver automaticamente se é um DVD-VR não finalizado
# TODO: mostrar espaço livre e ocupado
# TODO: mostrar tempo estimado de vídeo no DVD

# TODO: finalizar DVD
# 1) extrair IFOs e VOBs e LBAs 
# 2) alterar IFOs (remover menus, corrigir setores, corrigir parâmetros do vídeo nos menus, adicionar última VOB que não entrou no IFO)
# 2B) alterar IFOs (adicionar VOB adicional externa para preencher o espaço livre)
# 3) gerar sistema de ficheiros UDF
# 4) gerar .ISO com o novo sistema de ficheiros
# 5) testar o ISO
# 6) queimar no DVD original em duas partes: primeira pista com o UDF, última "pista" com novos vídeps












