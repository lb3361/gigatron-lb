# Load Quartus II Tcl Project package
package require ::quartus::project


# Open or create project
set project_name "basic"
if {[project_exists $project_name]} {
    project_open -revision $project_name $project_name
} else {
    project_new -revision $project_name $project_name
}

# Make assignments
set_global_assignment -name FAMILY MAX7000S
set_global_assignment -name DEVICE "EPM7128SQC100-15"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR "-1"
set_global_assignment -name MAX7000_DEVICE_IO_STANDARD TTL
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../top-pqfp100.tcl
set_global_assignment -name VERILOG_FILE ../main-basic.v
set_global_assignment -name OPTIMIZE_HOLD_TIMING OFF
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING OFF
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
export_assignments
project_close
