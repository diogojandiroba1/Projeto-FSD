create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
set_input_delay  0.5 -clock CLOCK_50 [remove_from_collection [all_inputs] [get_ports {CLOCK_50}]]
set_output_delay 0.5 -clock CLOCK_50 [all_outputs]
