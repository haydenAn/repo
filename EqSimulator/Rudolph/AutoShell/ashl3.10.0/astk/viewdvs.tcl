
# Copyright 2009 Rudolph Technologies, Inc. All Rights Reserved.
# This software is provided under license and may only be used in
# accordance with the terms of the respective license agreements
# of the owners of the same software, which include, but are not
# limited to, Rudolph Technologies, Inc. Where applicable, refer
# to on-line license agreements provided with the software.

# $Id: viewdvs.tcl,v 1.5 2000/08/02 20:23:56 karl Exp $
# $Log: viewdvs.tcl,v $
# Revision 1.5  2000/08/02 20:23:56  karl
# Fixed sys>waiting entry leak.
#
# Revision 1.4  2000/07/07  22:44:24  karl
# Added browse_dvs proc to support different DV viewers.
#
# Revision 1.3  1999/08/24  15:43:20  karl
# Added use of configurable editor.
# Took out sys>bin suppression.
#
# Revision 1.2  1997/10/29  23:26:28  love
# Modifed code to use a temporary file name generated by tempfilename
# instead of storing the data in a file name $env(HOME)/viewdvs.dvs.
# This was not portable to NT since $env(HOME) on NT has escapes for
# directory delimiters?  Freaky but true.
#
# Revision 1.1  1996/08/27  16:22:19  karl
# Initial revision
#
set dv_c 0

proc browsedvs {srvname {viewer anp} win} {
	set vibindings 0

	if [ catch {an_msgsend 0 $srvname "get CWD" -an_reply_cb "get_dv_info0 \
		viewer=\"$viewer\" vibindings=$vibindings win=$win"} ] {
        tk_messageBox -message "Could not send DV list request to $srvname." \
            -type ok -icon warning -parent $win
        }
}

proc viewdvs {srvname {vibindings 0}} {
	set viewer anp
	#puts "inside viewdvs vibindings=$vibindings"
	an_msgsend 0 $srvname "get CWD" -an_reply_cb "get_dv_info0 \
		viewer=\"$viewer\" vibindings=$vibindings"
}

# This is invoked when "Server Logs" is pressed.  It gets the CWD of the
# server, then request dv information.
an_proc get_dv_info0 {} {} {} {
	#set fileId [open jack a+ 0666]
	#puts $fileId "get_dv_info0 viewer=$viewer vibindings=$vibindings"

	global tcl_platform
	if { [info exists tcl_platform] && $tcl_platform(platform) == "windows" } {
	
		#for Windows use UNC instead of absolute path
		global env
		set computer_name $env(COMPUTERNAME)

		if [file isdirectory //$computer_name/Adventa_temp] {
			set dvfile //$computer_name/Adventa_temp/viewdvs_data[pid]
		} else {
 	      	tk_messageBox -message "You must create a network share at //$computer_name/Adventa_temp for storage of temporary files" -type ok -icon warning \
			-parent $win
			return
		}

	} else {
		set dvfile [tempfilename viewdvs_data[pid]]
	}

	an_msgsend 0 $fr store file=$dvfile -an_reply_cb \
		"get_dv_info1 file=$dvfile \
		viewer=\"$viewer\" vibindings=$vibindings win=$win"

}

an_proc get_dv_info1 {} {} {} {

	if {$reply != 0} {
      	tk_messageBox -message "Server $fr was unable to store DV file at $file.  Check that it has write access to the network share." -type ok -icon warning -parent $win
		return
	}
	
	an_delete_cb $currenv
	set temp ""
	scan $viewer "%s" temp
	if {$temp=="anp"} {
		append viewer " -buttons"
	}
	#set fileId [open jack a+ 0666]
	#puts $fileId "exec_and_wait \"$viewer $file\""
	#close $fileId

	#exec_and_wait "$viewer $file" "
	#	file delete -force $file
	#"
	#reformat the proc call
	exec_and_wait "$viewer $file" "file delete -force $file"


}

proc suck_sys_bin {textwidget} {
	set numlines [expr int([$textwidget index end])]
	set sysbinstart 0
	set sysbinend 0
	set level 0
	set path {}
	set l 0
	while {$l<$numlines} {
		set line [string trimleft [$textwidget get $l.0 $l.end]]
		if {[string range $line 0 0]=="\{"} {
			set node [lindex [split $line] 1]
			lappend path $node
		} elseif {[llength $path]>0 && [string range $line 0 0]=="\}"} {
			set path [lreplace $path end end]
		}
		if {$sysbinstart==0 &&
				[llength $path]==2 && [lindex $path 0]=="sys" &&
				[lindex $path 1]=="bin"} {
			set sysbinstart $l
		}
		if {$sysbinstart && $sysbinend==0 && [llength $path]<2} {
			set sysbinend $l
		}
		incr l
	}
	$textwidget configure -state normal
	$textwidget delete $sysbinstart.0 [expr $sysbinend+1].0
	$textwidget configure -state disabled
}

#source viedit.tcl
#source showfile.tcl
#viewdvs qsrv
	