#INITIALIZE
set enable_prelayout_timing 1
set working_dir [exec pwd]
set vsd_array_length [llength [split [lindex $argv 0] .]]
set input [lindex [split [lindex $argv 0] .] $vsd_array_length-1]
#CHECK ARGS
if {![regexp {^csv} $input] || $argc != 1} {
	puts "Error in usage"
	puts "Usage: ./vsdsynth <.csv>"
	puts "where <.csv> file has below inputs"
	exit
} else {
	set filename [lindex $argv 0]
	package require csv
	package require struct::matrix
	struct::matrix m
	set f [open $filename]
	csv::read2matrix $f m , auto
	close $f
	set columns [m columns]
	m add columns [m columns]
	m link my_arr
	set num_of_rows [m rows]
	set i 0

	while {$i < $num_of_rows} {
		puts "\nInfo: Setting $my_arr(0,$i) as '$my_arr(1,$i)'"
		if {$i == 0} {
			set [string map {" " ""} $my_arr(0,$i)] $my_arr(1,$i)
		} else {
			set [string map {" " ""} $my_arr(0,$i)] [file normalize $my_arr(1,$i)]
		}
		set i [expr {$i + 1}]
	}
}
#LIST VARS
puts "\nInfo: Below are the list of initial variables and their values. User can use these variables for further debug. Use 'puts <variable name>' command to query value of the variables below."
puts "DesignName = $DesignName"
puts "OutputDirectory = $OutputDirectory"
puts "NetlistDirectory = $EarlyLibraryPath"
puts "LateLibraryPath = $LateLibraryPath"
puts "ConstraintsFile = $ConstraintsFile"
#CHECK VAR INTEGRITY
if {![file isdirectory $OutputDirectory]} {
	puts "\nInfo: Cannot find output directory $OutputDirectory. Creating $OutputDirectory"
	file mkdir $OutputDirectory
} else {
	puts "\nInfo: Output directory found in path $OutputDirectory"
}
if {![file isdirectory $NetlistDirectory]} {
	puts "\nError: Cannot find netlist directory $NetlistDirectory. Exiting..."
	exit
} else {
	puts "\nInfo: Netlist directory found in path $NetlistDirectory"
}
if {![file exists $EarlyLibraryPath]} {
	puts "\nError: Cannot find early library at $EarlyLibraryPath. Exiting..."
	exit
} else {
	puts "\nInfo: Early Library found in path $EarlyLibraryPath"
}
if {![file exists $LateLibraryPath]} {
	puts "\nError: Cannot find early library at $LateLibraryPath. Exiting..."
	exit
} else {
	puts "\nInfo: Late Library found in path $LateLibraryPath"
}
if {![file exists $ConstraintsFile]} {
	puts "\nError: Cannot find constraints file at $ConstraintsFile. Exiting..."
	exit
} else {
	puts "\nInfo: Constraints File found in path $ConstraintsFile"
}
#START SDC
puts "\nInfo: Dumping SDC constraints for $DesignName"
::struct::matrix constraints
set chan [open $ConstraintsFile]
csv::read2matrix $chan constraints , auto
close $chan
set number_of_rows [constraints rows]
set number_of_columns [constraints columns]
#START CLOCK SDC
set clock_start [lindex [lindex [constraints search all CLOCKS] 0] 1]
set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
set input_start_column [lindex [lindex [constraints search all INPUTS] 0] 0]
set output_start_column [lindex [lindex [constraints search all OUTPUTS] 0] 0]

set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_delay] 0] 0]
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_delay] 0] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_delay] 0] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_delay] 0] 0]
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_slew] 0] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_slew] 0] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_slew] 0] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_slew] 0] 0]

set clock_freq_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] frequency] 0] 0]
set clock_duty_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] duty_cycle] 0] 0]

set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
set i [expr {$clock_start+1}]
set end_of_ports [expr {$input_ports_start - 1}]
puts "\nInfo-SDC: Working on clock constraints"
while  {$i < $end_of_ports} {
	puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell $clock_freq_start $i] -waveform \{0 [expr {[constraints get cell $clock_freq_start $i]*[constraints get cell $clock_duty_start $i]/100}]\} \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -early -rise [constraints get cell $clock_early_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -early -fall [constraints get cell $clock_early_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -late -rise [constraints get cell $clock_late_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -late -fall [constraints get cell $clock_late_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	set i [expr {$i + 1}]
}
#START INPUT SDC

set input_early_rise_delay_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_delay] 0] 0]
set input_early_fall_delay_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_delay] 0] 0]
set input_late_rise_delay_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_delay] 0] 0]
set input_late_fall_delay_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_delay] 0] 0]
set input_early_rise_slew_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_slew] 0] 0]
set input_early_fall_slew_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_slew] 0] 0]
set input_late_rise_slew_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_slew] 0] 0]
set input_late_fall_slew_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_slew] 0] 0]
set related_clock_start [lindex [lindex [constraints search rect $input_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] clocks] 0] 0]




set i [expr {$input_ports_start+1}]
set end_of_ports [expr {$output_ports_start - 1}]
puts "\nInfo-SDC: Working on input port constraints"
while  {$i < $end_of_ports} {
    set netlist [glob -dir $NetlistDirectory *.v]
    set tmp_file [open /tmp/1 w]
    foreach f $netlist {
        set fd [open $f]
        while {[gets $fd line] != -1} {
            set pattern1 " [constraints get cell 0 $i];"
            if {[regexp -all -- $pattern1 $line]} {
                set pattern2 [lindex [split $line ";"] 0]
                if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
                    set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
                    puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
                }
            }
        }
        close $fd
    }
    close $tmp_file
    set tmp_file [open /tmp/1 r]
    set tmp_file2 [open /tmp/2 w]
    puts -nonewline $tmp_file2 "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
    close $tmp_file
    close $tmp_file2
    set tmp_file2 [open /tmp/2 r]
    set count [llength [read $tmp_file2]]
    if {$count > 2} {
        set inp_ports [concat [constraints get cell 0 $i]*]
    } else {
        set inp_ports [constraints get cell 0 $i]
    }
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $inp_ports\]"
    
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock_start $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $inp_ports\]"
	set i [expr {$i + 1}]
    }
#START OUTPUT SDC

set output_early_rise_delay_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_rise_delay] 0] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_fall_delay] 0] 0]
set output_late_rise_delay_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_rise_delay] 0] 0]
set output_late_fall_delay_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_fall_delay] 0] 0]
set output_related_clock_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] clocks] 0] 0]
set output_load_start [lindex [lindex [constraints search rect $output_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] load] 0] 0]



set i [expr {$output_ports_start+1}]
set end_of_ports [expr {$number_of_rows - 1}]
puts "\nInfo-SDC: Working on output port constraints"
while  {$i <= $end_of_ports} {
    set netlist [glob -dir $NetlistDirectory *.v]
    set tmp_file [open /tmp/1 w]
    foreach f $netlist {
        set fd [open $f]
        while {[gets $fd line] != -1} {
            set pattern1 " [constraints get cell 0 $i];"
            if {[regexp -all -- $pattern1 $line]} {
                set pattern2 [lindex [split $line ";"] 0]
                if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
                    set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
                    puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
                }
            }
        }
        close $fd
    }
    close $tmp_file
    set tmp_file [open /tmp/1 r]
    set tmp_file2 [open /tmp/2 w]
    puts -nonewline $tmp_file2 "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
    close $tmp_file
    close $tmp_file2
    set tmp_file2 [open /tmp/2 r]
    set count [llength [read $tmp_file2]]
    if {$count > 2} {
        set out_ports [concat [constraints get cell 0 $i]*]
    } else {
        set out_ports [constraints get cell 0 $i]
    }
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $output_related_clock_start $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $out_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $output_related_clock_start $i]\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $out_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $output_related_clock_start $i]\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $out_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $output_related_clock_start $i]\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $out_ports\]"
    puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $i] \[get_ports $out_ports\]"
	set i [expr {$i + 1}]
    }

#YOSYS
#Hier Check

puts "\nInfo: Creating hierarchy check script to be used by YOSYS"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.hier.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
    set data $f
    puts -nonewline $fileId "\nread_verilog $f"
}
puts -nonewline $fileId "\nhierarchy -check"
close $fileId

puts "\nclose \"$OutputDirectory/$filename\"\n"
puts "\nChecking Hierarchy..."
set err [catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log } msg]
puts "error flag is $err"
if { [catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log } msg]  } {
    set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
    puts "log file name is $filename"
    set pattern {referenced in module}
    puts "pattern is $pattern"
    set count 0
    set fid [open $filename r]
    while {[gets $fid line] != -1} {
        incr count [regexp -all -- $pattern $line]
        if {[regexp -all -- $pattern $line]} {
            puts "\nError: module [lindex $line 2] is not part of design $DesignName. Please correct RTL in the path '$NetlistDirectory'"
            puts "\nInfo: Hierarchy check FAIL"
        }
    }
    close $fid 
} else {
    puts "\nInfo: Please find hierarchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more info"
}
#Synthesis
puts "\nInfo: Creating main synthesis script to be used by YOSYS"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
    set data $f
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
puts "\nInfo: Running Synthesis..."

if { [catch { exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.hierarchy_check.synthesis.log } msg]  } {
    puts "\nError: Synthesis failed due to errors. Please refer to log $OutputDirectory/$DesignName.synthesis.log for errors"
    exit
} else {
    puts "\nInfo: Please refer to log $OutputDirectory/$DesignName.synthesis.log"
}
#Reformat synth.v & prepare for OpenTimer
set fileId [open /tmp/1 "w"]
puts -nonewline $fileId [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]
close $fileId 
set output [open $OutputDirectory/$DesignName.final.synth.v "w"]
set filename "/tmp/1"
set fid [open $filename r]
while {[gets $fid line] != -1} {
    puts -nonewline $output [string map {"\\" ""} $line]
    puts -nonewline $output "\n"

}
close $fid 
close $output 
puts "\nInfo: Please find the synthesized netlist for $DesignName at below path. You can use this netlist for STA or PNR"
puts "\n$OutputDirectory/$DesignName.final.synth.v"

source /home/vsduser/Desktop/vsdflow/procs/reopenStdout.proc
source /home/vsduser/Desktop/vsdflow/procs/read_sdc.proc
source /home/vsduser/Desktop/vsdflow/procs/set_num_threads.proc
source /home/vsduser/Desktop/vsdflow/procs/read_lib.proc
source /home/vsduser/Desktop/vsdflow/procs/read_verilog.proc
read_sdc $OutputDirectory/$DesignName.sdc

reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCpu 6

read_lib -early $EarlyLibraryPath
read_lib -late $LateLibraryPath

read_verilog $OutputDirectory/$DesignName.final.synth.v
puts "set_timing_fpath $OutputDirectory/$DesignName.timing"

reopenStdout /dev/tty

#create spef file
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

set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "
close $conf_file
#run sta tool
set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results}]
set time_elapsed_in_sec "[expr {[lindex $time_elapsed_in_us 0]/1000000.0}]"
puts "\nInfo: STA finished in $time_elapsed_in_sec seconds"
puts "\nInfo: Refer $OutputDirectory/$DesignName.results for warnings and errors"
#output viol
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
#num viol
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_output_violations $count
close $report_file
#setup
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
#setup
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_setup_violations $count
close $report_file
#hold
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
#setup
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
	while {[gets $report_file line] != -1} {
		incr count [regexp -all -- $pattern $line]

	}
set Number_hold_violations $count
close $report_file
#Num instances
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
puts "\n\nSTA Results:"
set formatStr {%20s%20s%20s%20s%20s%20s%20s%20s%20s}
puts [format $formatStr "-----------" "-------" "--------------" "--------------" "---------------" "--------------" "--------------" "-------" "-------"]
puts [format $formatStr "Design Name" "Runtime" "Num Instances" "WNS Setup Delay" "FEP Setup Delay" "WNS Hold Delay" "FEP Hold Delay" "WNS RAT" "FEP RAT"]
puts [format $formatStr "-----------" "-------" "--------------" "--------------" "---------------" "--------------" "--------------" "-------" "-------"]
foreach design_name $DesignName runtime $time_elapsed_in_sec instance_count $Instance_count wns_setup $worst_negative_setup_slack fep_setup $Number_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
	puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}
