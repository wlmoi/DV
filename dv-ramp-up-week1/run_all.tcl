# Run all UART testbenches with Icarus Verilog.
set root [file dirname [info script]]
cd $root

set tests {001 002 003}
foreach t $tests {
    set tb "tb/uart_tb_${t}.sv"
    set out "waves/uart_tb_${t}.out"

    puts "=== UART-${t} ==="
    if {[catch {exec iverilog -g2012 -o $out $tb rtl/uart.sv} err]} {
        puts "ERROR: compile failed for ${tb}"
        puts $err
        continue
    }

    if {[catch {exec vvp $out} sim_out]} {
        puts "ERROR: simulation failed for ${tb}"
        puts $sim_out
        continue
    }

    if {$sim_out ne ""} {
        puts $sim_out
    }
}
