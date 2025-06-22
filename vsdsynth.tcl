########################################################################################################################################################################
set enable_prelayout_timing 1
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------Auto-creation of variables----------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
package require csv
package require struct::matrix
#-------------------------------------------------------------------------------------------------------------------------------------#
set filename [lindex $argv 0]
struct::matrix m
#-----------------------------------------------matrices expressed as column, row-----------------------------------------------------#
set f [open $filename]
csv::read2matrix $f m , auto
close $f
#-------------------------------------------------------------------------------------------------------------------------------------#
set columns [m columns]
#syntax to add the number of columns
#m add columns $columns
#convert matrix to an array called my_arr
m link my_arr
set number_of_rows [m rows]
#----------------------------------------------creating variables from design details ------------------------------------------------#
set i 0
#1-treating the first row differently as it's the only value which is not a path 
#2- using the same variable names mentioned in the CSV file after removing the spaces between words eg Design Name becomes DesignName
#3- remove spaces in the first column and the file path name is normalized ie full expanded path no '~' symbols 

	while {$i < $number_of_rows} {
		puts "\nInfo: Setting $my_arr(0,$i) as '$my_arr(1,$i)'"
		#----------------------1---------------------------#
		if {$i == 0} {
			#----------------------2---------------------------#
			set [string map {" " ""} $my_arr(0,$i)] $my_arr(1,$i)
		} else {
			#----------------------3---------------------------#
		        set [string map {" " ""} $my_arr(0,$i)] [file normalize $my_arr(1,$i)]  	
		} 
		set i [expr {$i +1}]
	}

puts "\nInfo: Below are the list of initial variables and their values"
puts "\nDesignName = $DesignName"
puts "\nOutputDirectory = $OutputDirectory"
puts "\nNetlistDirectory = $NetlistDirectory"
puts "\nEarlyLibraryPath = $EarlyLibraryPath"
puts "\nLateLibraryPath = $LateLibraryPath"
puts "\nConstraintsFile = $ConstraintsFile"
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------Checking path validity----------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------checking output directory------------------------------------------------------#
	if {![file isdirectory $OutputDirectory]} {
		puts "\nInfo: Cannot find $OutputDirectory. Creating $OutputDirectory"
		file mkdir $OutputDirectory
	} else {
		puts "\nInfo: Output directory found in $OutputDirectory"
	}
#------------------------------------------------------checking input RTL directory path----------------------------------------------#
	if {![file isdirectory $NetlistDirectory]} {
		puts "\nError: Cannot find $NetlistDirectory. Please check the path. Exiting . . "
		exit
	} else {
		puts "\nInfo: Found the input RTL Netlist at $NetlistDirectory"
	}
#-------------------------------------------------------checking input Lib files path-------------------------------------------------#	
	if {![file exists $EarlyLibraryPath]} {
		puts "\nError: Cannot find $EarlyLibraryPath. Please check the path. Exiting . . "
		exit
	} else {
		puts "\nInfo: Found the early cell library files at $EarlyLibraryPath"
	}
#-------------------------------------------------------------------------------------------------------------------------------------#
	if {![file exists $LateLibraryPath]} {
		puts "\nError: Cannot find $LateLibraryPath. Please check the path. Exiting . . "
		exit
	} else {
		puts "\nInfo: Found the late cell library files at $LateLibraryPath"
	}
#-------------------------------------------------------checking input constraints files path-----------------------------------------#	
	if {![file exists $ConstraintsFile]} {
		puts "\nError: Cannot find $ConstraintsFile. Please check the path. Exiting . . "
		exit
	} else {
		puts "\nInfo: Found the constraints files at $ConstraintsFile"
	}
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------Processing SDC constraints----------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------converting constraints csv into matrix-----------------------------------------#
puts "\nInfo: Dumping SDC constraints for $DesignName"
struct::matrix constraints
set chan [open $ConstraintsFile]
csv::read2matrix $chan constraints , auto
close $chan
set number_of_rows [constraints rows]
set number_of_columns [constraints columns]
#-------------------------------------------------------parsing the constraints matrix------------------------------------------------#
#4-search all - matrix command ---------- find the {a,b} where CLOCKS is found -----since its the only value lindex 0 = {a,b}-----lindex within this ---lindex 1 = b ----lindex 0 = a--#
#5-search for particular latency values among CLOCKS which will be used to print out the set_clock_latency sdc command ; search rect col1 row1 col2 row2 - lhs corner rhs corner of the rectangle we want to search
#--------------------------------------------------------------------4----------------------------------------------------------------#
set clock_start [lindex [lindex [constraints search all CLOCKS] 0] 1]
set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
#------------------------------------------------logic to find where inputs columns end-----------------------------------------------#
set input_ports_end_col 0
set temp_string [constraints get cell $clock_start $input_ports_start]
#-----------------------------------------------loop till you find an empty element---------------------------------------------------#
	while {$temp_string ne ""} {
		set input_ports_end_col [expr {$input_ports_end_col +1}]
	        set temp_string [constraints get cell $input_ports_end_col $input_ports_start]
	}
#------------------------------------------------logic to find where outputs columns end----------------------------------------------#
	set output_ports_end_col 0
	set temp_string [constraints get cell $clock_start $output_ports_start]
#-----------------------------------------------loop till you find an empty element---------------------------------------------------#
	while {$temp_string ne ""} {
		set output_ports_end_col [expr {$output_ports_end_col +1}]
	        set temp_string [constraints get cell $output_ports_end_col $output_ports_start]
	}
#--------------------------------------------------------------CLOCKS-----------------------------------------------------------------#	
set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_rise_delay] 0] 0]
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_fall_delay] 0] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_rise_delay] 0] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_fall_delay] 0] 0]
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_rise_slew] 0] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] early_fall_slew] 0] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_rise_slew] 0] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] late_fall_slew] 0] 0]
set clock_frequency_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] frequency] 0] 0]
set clock_duty_cycle_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns -1}] [expr {$input_ports_start -1}] duty_cycle] 0] 0]
#---------------------------------------------------------------INPUTS----------------------------------------------------------------#	
set input_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] early_rise_delay] 0] 0]
set input_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] early_fall_delay] 0] 0]
set input_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] late_rise_delay] 0] 0]
set input_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] late_fall_delay] 0] 0]

set input_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] early_rise_slew] 0] 0]
set input_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] early_fall_slew] 0] 0]
set input_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] late_rise_slew] 0] 0]
set input_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] late_fall_slew] 0] 0]
set related_clock [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$input_ports_end_col -1}] [expr {$output_ports_start -1}] clocks] 0] 0]
#-----------------------------------------------------------------OUTPUTS-------------------------------------------------------------#
set output_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col-1}] [expr {$number_of_rows -1}] early_rise_delay] 0] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col-1}] [expr {$number_of_rows -1}] early_fall_delay] 0] 0]
set output_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col-1}] [expr {$number_of_rows -1}] late_rise_delay] 0] 0]
set output_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col-1}] [expr {$number_of_rows -1}] late_fall_delay] 0] 0]
set related_clock_out [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col -1}] [expr {$number_of_rows -1}] clocks] 0] 0]
set output_load_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$output_ports_end_col -1}] [expr {$number_of_rows -1}] load] 0] 0]
#---------------------------------------------INPUTS & OUTPUTS file init to identify bus ports-----------------------------------------#
set netlist [glob -dir $NetlistDirectory *.v]
set temp_file_inp [open /tmp/temp_inp "w"]
set temp_file_out [open /tmp/temp_out "w"]
	foreach f $netlist {
		set fd [open $f]
		while {[gets $fd line] != -1} {
#--------------------------find all the lines which start with the word 'input' and store in a temp file-------------------------------#
			if {[regexp {^input} $line]} {
				set pattern1 [lindex [split $line ";"] 0]
				puts -nonewline $temp_file_inp "$pattern1\n"
			}
#--------------------------find all the lines which start with the word 'output' and store in a temp file------------------------------#
			if {[regexp {^output} $line]} {
				set pattern1 [lindex [split $line ";"] 0]
				puts -nonewline $temp_file_out "$pattern1\n"
			}
		}
		close $fd
	}
        close $temp_file_inp
	close $temp_file_out
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------- Writing to the SDC file---------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
#---------------------------------------------------------------CLOCKS----------------------------------------------------------------#
set i [expr {$clock_start+1}]
set end_of_ports [expr {$input_ports_start-1}]
puts "\nInfo-SDC: Working on clock constraints . . ."
	while {$i < $end_of_ports} {
                set freq [constraints get cell $clock_frequency_start $i]
	        set dcycle [constraints get cell $clock_duty_cycle_start $i]	
	        puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell $clock_start $i] -period $freq -waveform \{0 [expr {$freq*$dcycle/100}]\} \[get_ports [constraints get cell $clock_start $i]\]"	
	      #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		puts -nonewline $sdc_file "\nset_clock_transition -rise -min [constraints get cell $clock_early_rise_slew_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_early_fall_slew_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_transition -rise -max [constraints get cell $clock_late_rise_slew_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_transition -fall -max [constraints get cell $clock_late_fall_slew_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
              #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell $clock_start $i]\]"
		set i [expr {$i +1}]
	}
	
#----------------------------------------------------------------INPUTS---------------------------------------------------------------#
set i [expr {$input_ports_start + 1}]
set end_of_ports [expr {$output_ports_start -1}]
set temp_file_inp [open /tmp/temp_inp r]
puts "\nInfo SDC: Working on IO constraints . . . ."
puts "\nInfo SDC: Categorizing input ports as bits and busses"
	while {$i < $end_of_ports} {
		while {[gets $temp_file_inp line] != -1} {
			set pattern1 [constraints get cell $clock_start_column $i]
#--------------------------------------------search for the input port in the temp file-----------------------------------------------#
			if {[regexp -all $pattern1 $line]} {
#--------------------------------------------find ':' ie a bus and append * to its name-----------------------------------------------#
				if {[regexp -all ":" $line]} {
					set pattern2 [concat $pattern1*]
				} else {
					set pattern2 $pattern1
				}
#--------------------------------------------------break out of loop if found---------------------------------------------------------#
				break
			} 

		}
#-------------------------------------reset the file read pointer to the beginning of the file----------------------------------------#
                seek $temp_file_inp 0 start
	      #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $pattern2\]"
	      #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $pattern2\]"
		
		set i [expr {$i +1}]

	}

        close $temp_file_inp
#----------------------------------------------------------------------OUPUTS---------------------------------------------------------#
set i [expr {$output_ports_start + 1}]
set end_of_ports $number_of_rows
#set temp_file_out [open ./temp_out r]
set temp_file_out [open /tmp/temp_out r]
puts "\nInfo SDC: Working on IO constraints . . . ."
puts "\nInfo SDC: Categorizing output ports as bits and busses"
	while {$i < $end_of_ports} {
		while {[gets $temp_file_out line] != -1} {
#-------------------------------------------------search for the output port in the temp file-----------------------------------------#
			set pattern1 [constraints get cell $clock_start_column $i]
			if {[regexp -all $pattern1 $line]} {
#-------------------------------------------------find ':' ie a bus and append * to its name------------------------------------------#
				if {[regexp -all ":" $line]} {
					set pattern2 [concat $pattern1*]
				} else {
					set pattern2 $pattern1
				}
#--------------------------------------------------------break out of loop if found---------------------------------------------------#
				break
			} 

		}
#-------------------------------------reset the file read pointer to the beginning of the file-----------------------------------------#
                seek $temp_file_inp 0 start
	      #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock_out $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock_out $i]\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock_out $i]\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock_out $i]\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $pattern2\]"
		puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $i] \[get_ports $pattern2\]"
	      #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#	
		
		set i [expr {$i +1}]

	}

	close $temp_file_out
        close $sdc_file
	puts "\nInfo : SDC file created. Please use constraints in the path $OutputDirectory/$DesignName.sdc"
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------Hierarchy check-------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Creating hierarchy check script to be used by Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.hier.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
	foreach f $netlist {
		#set data $f
		puts -nonewline $fileId "\nread_verilog $f"
	}
	puts -nonewline $fileId "\nhierarchy -check"
	close $fileId
#--------------------------------------------------------Error Handling---------------------------------------------------------------#
set count 0
	if {[catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log } msg]} {
		set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
#--------------------------'referenced in module' are the specific words used by Yosys in the error log-------------------------------#
		set pattern {referenced in module}
		set fid [open $filename r]
		while {[gets $fid line] != -1 } {
			#incr count [regexp -all -- $pattern $line]
			if {[regexp -all -- $pattern $line]} {
			        incr count 1
				puts "\nError: module [lindex $line 2] is not a part of the design $DesignName. Please correct RTL in the path '$NetlistDirectory'"
				puts "\nInfo: Hierarchy check FAIL"
			}
		}
		close $fid

	}
	
	if {$count == 0} {
		puts "\nInfo: Hierarchy check PASS"
	}	
puts "\nInfo: Please find hierarchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log]"

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------------------------------------Main Synthesis Script--------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Creating Main synthesis script for Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
	foreach f $netlist {
		#set data $f
		puts -nonewline $fileId "\nread_verilog $f"
	}
	puts -nonewline $fileId "\nhierarchy -top $DesignName"
	puts -nonewline $fileId "\nsynth -top $DesignName"
	puts -nonewline $fileId "\nsplitnets -ports -format __\ndfflibmap -liberty ${LateLibraryPath}\nopt"
	puts -nonewline $fileId "\nabc -liberty ${LateLibraryPath}"
	puts -nonewline $fileId "\nflatten"
        puts -nonewline $fileId "\nclean -purge\niopadmap -outpad BUFX2 A:Y -bits\nopt\nclean"
	puts -nonewline $fileId "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
	close $fileId
puts "\nInfo: Synthesis script created and can be accessed from path $OutputDirectory/$DesignName.ys"
puts "\nInfo: Running Synthesis . . . "
#------------------------------------------------------Running Synthesis--------------------------------------------------------------#
	if {[catch { exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log } msg]} {
		puts "\nError: Synthesis FAIL. Please refer $OutputDirectory/$DesignName.synthesis.log for errors"
		exit
	} else {
		puts "\nInfo: Synthesis PASS. Please refer to log $OutputDirectory/$DesignName.synthesis.log"
	}
#----------------------------------------------------Editing Synth.v file for OpenTimer-----------------------------------------------#
#------------------------------------need to remove lines "(* -------- *)" and remove "\" char ---------------------------------------#
set y_out [open $OutputDirectory/$DesignName.synth.v r]
set temp_file_1 [open /tmp/temp_file_s "w"]
	while {[gets $y_out line] != -1} {
#------------------------------------------------------get all lines not having "(*" or "/*"------------------------------------------#
		if {![regexp {(\(\*)|(\/\*)} $line]} {
			puts -nonewline $temp_file_1 "$line\n"
		}
	}
	close $y_out
	close $temp_file_1

set y_out_fin [open $OutputDirectory/$DesignName.final.synth.v w]
set temp_file_1 [open /tmp/temp_file_s r]
	while {[gets $temp_file_1 line] != -1} {
#-----------------------------------------------------------replace "\" with ""------------------------------------------------------#
		puts -nonewline $y_out_fin [string map {"\\" ""} $line]
		puts -nonewline $y_out_fin "\n"
	}
	close $y_out_fin
	close $temp_file_1

puts "\nInfo: The below path contains the synthesized netlist which can be used for PNR and STA."
puts "\n$OutputDirectory/$DesignName.final.synth.v"
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
#----------------------------------------------------------------------STA using  OpenTimer-----------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Timing Analysis Started . . ."
puts "\nInfo: Initializing number of threads, libraries, sdc, verilog netlist path . . ."
source /home/vsduser/Desktop/vsd_ws_2025/procs/reopenStdout.proc
source /home/vsduser/Desktop/vsd_ws_2025/procs/set_num_threads.proc
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#
#--------------------------------------------redirecting output to .conf file in the path---------------------------------------------#
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#
reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCpu 4

source /home/vsduser/Desktop/vsd_ws_2025/procs/read_lib.proc
read_lib -early $EarlyLibraryPath
read_lib -late $LateLibraryPath

source /home/vsduser/Desktop/vsd_ws_2025/procs/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v

#--------------------------------------------creating the timing file for OpenTimer---------------------------------------------------#
set temp_ott1 [open /tmp/temp_ott1 "w"]
#----------------------------------------------------------CLOCKS---------------------------------------------------------------------#
set i [expr {$clock_start+1}]
set end_of_ports [expr {$input_ports_start-1}]
        while {$i < $end_of_ports} {
                set freq [constraints get cell $clock_frequency_start $i]
                set dcycle [expr {100 - [constraints get cell $clock_duty_cycle_start $i]}]
                puts -nonewline $temp_ott1 "clock [constraints get cell $clock_start_column $i] $freq $dcycle\n"
                puts -nonewline $temp_ott1 "at [constraints get cell $clock_start_column $i] [constraints get cell $clock_early_rise_delay_start $i] [constraints get cell $clock_early_fall_delay_start     $i] [constraints get cell $clock_late_rise_delay_start $i] [constraints get cell $clock_late_fall_delay_start $i]\n"
                puts -nonewline $temp_ott1 "slew [constraints get cell $clock_start_column $i] [constraints get cell $clock_early_rise_slew_start $i] [constraints get cell $clock_early_fall_slew_start     $i] [constraints get cell $clock_late_rise_slew_start $i] [constraints get cell $clock_late_fall_slew_start $i]\n"
                set i [expr {$i +1}]
        }

#-----------------------------------------------------------INPUTS--------------------------------------------------------------------#
set i [expr {$input_ports_start + 1}]
set end_of_ports [expr {$output_ports_start -1}]
set temp_file_inp [open /tmp/temp_inp r]
        while {$i < $end_of_ports} {
                while {[gets $temp_file_inp line] != -1} {
                        set pattern1 [constraints get cell $clock_start_column $i]
#------------------------------------------------search for the input port in the temp file-------------------------------------------#
                        if {[regexp -all $pattern1 $line]} {
#------------------------------------------------find ':' ie a bus and append * to its name-------------------------------------------#
                                if {[regexp -all ":" $line]} {
                                        set pattern2 [concat $pattern1*]
                                } else {
                                        set pattern2 $pattern1
                                }
#----------------------------------------------------break out of loop if found-------------------------------------------------------#
                                break
                        }

                }
#------------------------------------------reset the file read pointer to the beginning of the file-----------------------------------#
                seek $temp_file_inp 0 start
                puts -nonewline $temp_ott1 "at $pattern2 [constraints get cell $input_early_rise_delay_start $i] [constraints get cell $input_early_fall_delay_start $i] [constraints get cell $input_late_rise_delay_start $i] [constraints get cell $input_late_fall_delay_start $i]\n"
                puts -nonewline $temp_ott1 "slew $pattern2 [constraints get cell $input_early_rise_slew_start $i] [constraints get cell $input_early_fall_slew_start $i] [constraints get cell $input_late_rise_slew_start $i] [constraints get cell $input_late_fall_slew_start $i]\n"
                set i [expr {$i +1}]

        }

        close $temp_file_inp
#------------------------------------------------------------OUPUTS-------------------------------------------------------------------#
set i [expr {$output_ports_start + 1}]
set end_of_ports $number_of_rows
set temp_file_out [open /tmp/temp_out r]
        while {$i < $end_of_ports} {
                while {[gets $temp_file_out line] != -1} {
#------------------------------------------search for the output port in the temp file------------------------------------------------#
                        set pattern1 [constraints get cell $clock_start_column $i]
                        if {[regexp -all $pattern1 $line]} {
#------------------------------------------find ':' ie a bus and append * to its name-------------------------------------------------#
                                if {[regexp -all ":" $line]} {
                                        set pattern2 [concat $pattern1*]
                                } else {
                                        set pattern2 $pattern1
                                }
#-----------------------------------------------break out of loop if found------------------------------------------------------------#
                                break
                        }

                }
#------------------------------------reset the file read pointer to the beginning of the file-----------------------------------------#
                seek $temp_file_inp 0 start
                puts -nonewline $temp_ott1 "rat $pattern2 [constraints get cell $output_early_rise_delay_start $i] [constraints get cell $output_early_fall_delay_start $i] [constraints get cell $output_late_rise_delay_start $i] [constraints get cell $output_late_fall_delay_start $i]\n"
                puts -nonewline $temp_ott1 "load $pattern2 [constraints get cell $output_load_start $i]\n"
                set i [expr {$i +1}]

        }

        close $temp_file_out
        close $temp_ott1
#-------------------------------------------------------------------------------------------------------------------------------------#
set ot_timing_file [open $OutputDirectory/$DesignName.timing "w"]
set timing_file [open /tmp/temp_ott1 r]
	while {[gets $timing_file line] != -1} {
		if {[regexp -all -- {\*} $line]} {
			set bussed [lindex [lindex [split $line "*"] 0] 1]
			set final_synth_netlist [open $OutputDirectory/$DesignName.final.synth.v r]
			while {[gets $final_synth_netlist line2] != -1} {
				if {[regexp -all -- $bussed $line2] && [regexp -all -- {input} $line2] && ![string match "" $line]} { 
					puts -nonewline $ot_timing_file "[lindex [lindex [split $line "*"] 0] 0] [lindex [lindex [split $line2 ";"] 0] 1][lindex [split $line "*"] 1]\n"
				} elseif {[regexp -all -- $bussed $line2] && [regexp -all -- {output} $line2] && ![string match "" $line]} {
					puts -nonewline $ot_timing_file "[lindex [lindex [split $line "*"] 0] 0] [lindex [lindex [split $line2 ";"] 0] 1][lindex [split $line "*"] 1]\n"
				}
			}

		} else {
			puts -nonewline $ot_timing_file "$line\n"
		}
	}
	close $timing_file
	close $ot_timing_file
puts "set_timing_fpath $OutputDirectory/$DesignName.timing"
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#
#--------------------------------------------redirecting output back to console stdout------------------------------------------------#
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#
reopenStdout /dev/tty
#-------------------------------------------------------------creating SPEF file------------------------------------------------------#
if {$enable_prelayout_timing == 1} {
	puts "\nInfo: enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"
	set spef_file [open $OutputDirectory/$DesignName.spef w]
	puts $spef_file "*SPEF \"IEEE 1481-1998\" "
	puts $spef_file "*DESIGN \"$DesignName\" "
	puts $spef_file "*DATE \"Tue Sep 25 11:51:50 2012\" "
	puts $spef_file "*VENDOR \"TAU 2015 Contest\" "
	puts $spef_file "*PROGRAM \"Benchmark Parasitic Generator\" "
	puts $spef_file "*VERSION \"0.0\" "
	puts $spef_file "*DESIGN_FLOW \"NETLIST_TYPE_VERILOG\" "
	puts $spef_file "*DIVIDER / "
	puts $spef_file "*DELIMITER : "
	puts $spef_file "*BUS_DELIMITER [ ] "
	puts $spef_file "*T_UNIT 1 PS "
	puts $spef_file "*C_UNIT 1 FF "
	puts $spef_file "*R_UNIT 1 KOHM"
	puts $spef_file "*L_UNIT 1 UH"
}
close $spef_file
#----------------------------------------------------------Appending some more info---------------------------------------------------#
set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "
close $conf_file
#----------------------------------------------------------passing input to OpenTimer-------------------------------------------------#
set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results}]
set time_elapsed_in_sec "[expr {[lindex $time_elapsed_in_us 0]/1000000.0}]"
puts "\nInfo: STA finished in $time_elapsed_in_sec seconds"
puts "\nInfo: Refer $OutputDirectory/$DesignName.results for warnings and errors"
#---------------------------------------------------------find the worst output violation---------------------------------------------#
set worst_RAT_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {RAT}
	while {[gets $report_file line] != -1 } {
		if {[regexp $pattern $line]} {
			set worst_RAT_slack "[expr {[lindex $line 3]/1000.0}]ns"
			break
		} else {
			continue
		}
		
	}
close $report_file
#----------------------------------------------------------find the no. of output violations------------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_output_violations $count
close $report_file
#-----------------------------------------------------------find the worst setup violation--------------------------------------------#
set worst_negative_setup_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}
	while {[gets $report_file line] != -1 } {
		if {[regexp $pattern $line]} {
			set worst_negative_setup_slack "[expr {[lindex $line 3]/1000.0}]ns"
			break
		} else {
			continue
		}
		
	}
close $report_file
#-----------------------------------------------------------find the no. of setup violations------------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_setup_violations $count
close $report_file
#------------------------------------------------------------find the worst hold violation--------------------------------------------#
set worst_negative_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}
	while {[gets $report_file line] != -1 } {
		if {[regexp $pattern $line]} {
			set worst_negative_hold_slack "[expr {[lindex $line 3]/1000.0}]ns"
			break
		} else {
			continue
		}
		
	}
close $report_file
#------------------------------------------------------------find the no. of setup violations-----------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_hold_violations $count
close $report_file
#---------------------------------------------------------------find the no. of instances---------------------------------------------#
set pattern {Num of gates}
set report_file [open $OutputDirectory/$DesignName.results r]
	while {[gets $report_file line] != -1} {
		if {[regexp -all -- $pattern $line]} {
			set Instance_count [lindex [join $line " "] 4]
			break
		} else {
			continue
		}
	}
close $report_file
#---------------------------------------------------------------reporting the results-------------------------------------------------#
puts "										****PRELAYOUT TIMING RESULTS****						"
set formatStr {%20s%20s%20s%20s%20s%20s%20s%20s%20s}
puts [format $formatStr "-----------" "-------" "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
puts [format $formatStr "Design Name" "Runtime" "Instance Count" "WNS Setup" "FEP Setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT"]
puts [format $formatStr "-----------" "-------" "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
foreach design_name $DesignName runtime $time_elapsed_in_sec instance_count $Instance_count wns_setup $worst_negative_setup_slack fep_setup $Number_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
	puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}
########################################################################################################################################################################
