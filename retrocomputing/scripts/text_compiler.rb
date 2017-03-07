


def get_entries_from_file smsbackup_file

	entries =  `type \"#{smsbackup_file}\"`
	
	entry_list = entries.split(/\n/)
	
	#\;(.*)\;(.*)\;(.*)\;(.*)\;(.*)
	
	puts "entry_list: \\n\n #{entry_list}"
	
	return entry_list
end


def zx81_process_text_file_entries entries, target_dir, file_name
	puts "Converting XML to EML ... \n"
	
	start_index = 1000
	
	index = start_index	
	
	header_string = "1 REM Created with Text Compiler from text file\n"
	
	eml_file_string = ""
	
	entries.each do |entry|
			
	
		# Parse fields
		
		line = entry.delete("!'")
				
		
		# Write BASIC file
		
		eml_file_string = eml_file_string + "#{index} LET T$(#{index-start_index+1}) = \"#{line}\"\n"
					
				
		index = index + 1
	end
	
	eml_file_string = header_string + "50  LET NLINES=#{index-start_index}\n100 DIM T$(NLINES,210)\n" + eml_file_string
	
	eml_file_string = eml_file_string + "2000 REM Passa livro\n"
	eml_file_string = eml_file_string + "2010 FOR I=1 TO NLINES\n"
	eml_file_string = eml_file_string + "2015 CLS\n"
	eml_file_string = eml_file_string + "2020 PRINT T$(I)\n"
	eml_file_string = eml_file_string + "2025 PAUSE 250\n"
	eml_file_string = eml_file_string + "2030 NEXT I\n"
	eml_file_string = eml_file_string + "2100 GOTO 2000\n"
	
	target_filename = "#{target_dir}\\ZX81.tmp.bas"
		
	File.open(target_filename, 'w') { 
			|file| file.write(eml_file_string)
	}
	
	puts eml_file_string
	
	system "\"#{ZX81_BASIC_COMPILER}\" -o #{file_name}.zx81.p ZX81.tmp.bas"
end

def c64_process_text_file_entries entries, target_dir, file_name
	puts "Converting TXT to D64 & PRG ... \n"
	
	start_index = 1000
	
	index = start_index	
	
	header_string = "1 rem Created with Obsoletech Text Compiler from text file\n"
	
	eml_file_string = ""
	
	entries.each do |entry|
			
	
		# Parse fields
		
		line = entry.delete("!'").downcase
				
		
		# Write BASIC file
		
		eml_file_string = eml_file_string + "#{index} let t$(#{index-start_index+1}) = \"#{line}\"\n"
					
				
		index = index + 1
	end
	
	eml_file_string = header_string + "50 let nlines=#{index-start_index}\n100 dim t$(nlines)\n" + eml_file_string
	
	eml_file_string = eml_file_string + "2000 rem passa livro\n"
	eml_file_string = eml_file_string + "2005 poke 53280,2: poke 53281,10: print chr$(158)\n"
	eml_file_string = eml_file_string + "2010 for i=1 to nlines\n"
	eml_file_string = eml_file_string + "2015 print chr$(147)\n"
	eml_file_string = eml_file_string + "2020 print t$(i)\n"
	eml_file_string = eml_file_string + "2025 ti$=\"000000\" : wait 162,64\n"
	eml_file_string = eml_file_string + "2030 next i\n"
	eml_file_string = eml_file_string + "2100 go to 2000\n"
	
	target_filename = "#{target_dir}\\C64\\C64.tmp.bas"
		
	File.open(target_filename, 'w') { 
			|file| file.write(eml_file_string)
	}
	
	puts eml_file_string
	
	system "\"#{C64_BASIC_TO_PRG_CONVERTER}\" -w2 -o C64\\#{file_name}.c64.prg C64\\C64.tmp.bas"
	system "\"#{C64_DISK_EDITOR}\" -format \"textdisk,01\" d64 C64\\#{file_name}.c64.d64"
	system "\"#{C64_DISK_EDITOR}\" -attach C64\\#{file_name}.c64.d64 -write C64\\#{file_name}.c64.prg textshow"
end


def zxspectrum_process_text_file_entries entries, target_dir, file_name
	puts "Converting TXT to TAP ... \n"
	
	start_index = 1000
	
	index = start_index	
	
	header_string = "1 REM Created with Text Compiler from text file\n"
	
	eml_file_string = ""
	
	entries.each do |entry|
			
	
		# Parse fields
		
		line = entry.encode('UTF-8').delete("!'´")
				
		
		# Write BASIC file
		
		eml_file_string = eml_file_string + "#{index} LET T$(#{index-start_index+1}) = \"#{line}\"\n"
					
				
		index = index + 1
	end
	
	eml_file_string = header_string + "50  LET NLINES=#{index-start_index}\n100 DIM T$(NLINES,210)\n" + eml_file_string
	
	eml_file_string = eml_file_string + "2000 REM Passa livro\n"
	eml_file_string = eml_file_string + "2005 BORDER 2: PAPER 2: INK 7: BRIGHT 1\n"
	eml_file_string = eml_file_string + "2010 FOR I=1 TO NLINES\n"
	eml_file_string = eml_file_string + "2015 CLS\n"
	eml_file_string = eml_file_string + "2020 PRINT T$(I)\n"
	eml_file_string = eml_file_string + "2025 PAUSE 250\n"
	eml_file_string = eml_file_string + "2030 NEXT I\n"
	eml_file_string = eml_file_string + "2100 GO TO 2000\n"
	
	target_filename = "#{target_dir}\\ZXSpectrum.tmp.bas"
		
	File.open(target_filename, 'w') { 
			|file| file.write(eml_file_string)
	}
	
	puts eml_file_string
	
	system "\"#{ZX_SPECTRUM_BASIC_COMPILER}\" -sTEXTPLAYER -a1 ZXSpectrum.tmp.bas #{file_name}.zxspectrum.tap"
end



def process_text_file_entries entries, target_dir, file_name
	zx81_process_text_file_entries entries, target_dir, file_name
	zxspectrum_process_text_file_entries entries, target_dir, file_name
	c64_process_text_file_entries entries, target_dir, file_name
end

ZX81_BASIC_COMPILER="D:\\Program Files (x86)\\Zx\\ZX81\\zxtext2p\\zxtext2p.exe"
ZX_SPECTRUM_BASIC_COMPILER="D:\\Program Files (x86)\\Zx\\bas2tap\\bas2tap.exe"

C64_WINVICE_PATH="D:\\Mais documentos\\Projectos\\claxon2\\Emuladores\\WinVICE-2.4-x64"
C64_BASIC_TO_PRG_CONVERTER="#{C64_WINVICE_PATH}\\petcat.exe"
C64_DISK_EDITOR="#{C64_WINVICE_PATH}\\c1541.exe"


#2 rem http://www.c64-wiki.com/index.php/Color
# petcat.exe -w2 -o c64.test.prg -- ..\c64.test.bas
# c1541 -format "your disk,01" d64 vic20.d64
# c1541 -attach vic20.d64 -write c64.test.prg gastwirt
#   Writing file `C64.TEST.PRG' as `GASTWIRT' to unit 8.



puts "Obsoletech text_compiler.rb - ..."
puts "-------------\n\n"

entries = get_entries_from_file ARGV[0]
process_text_file_entries entries, ".", ARGV[0]

