`timescale 1ns / 1ps

module counter_with_adder_tb;

    reg clk;
    reg reset;
    reg [3:0] add_value;
    wire [31:0] count;

    // Instantiate the top module
    counter_with_adder uut (
        .clk(clk),
        .reset(reset),
        .add_value(add_value),
        .count(count)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // Dump waveform for GTKWave
        $dumpfile("counter_with_adder.vcd");
        $dumpvars(0, counter_with_adder_tb);

        // Initialize signals
        clk = 0;
        reset = 1;
        add_value = 4'd0;

        // Apply reset
        #10 reset = 0;

        // Add 3 every clock
        add_value = 4'd3;
        #40;

        // Change increment value to 5
        add_value = 4'd5;
        #40;

        // Reset again
        reset = 1;
        #10 reset = 0;

        // Add 2 every clock
        add_value = 4'd2;
        #30;

        $finish;
    end

endmodule
