// 32-bit Adder that adds a 4-bit value to a 32-bit value
// This module is purely combinational

module adder_32_4 (
    input  [31:0] A,        // 32-bit input (current counter value)
    input  [3:0]  B,        // 4-bit input number
    output [31:0] Sum       // 32-bit output (A + B)
);

    // Zero-extend B to 32 bits and add
    assign Sum = A + {{28{1'b0}}, B};

endmodule

// 32-bit Counter Register
// Updates its value on the positive edge of the clock

module counter32 (
    input clk,
    input reset,
    input [31:0] next_value,   // Value to be loaded into counter
    output reg [31:0] count
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 32'b0;     // Reset counter to zero
        else
            count <= next_value; // Load new value
    end

endmodule

// Top module connecting adder and counter using instantiation

module counter_with_adder (
    input clk,
    input reset,
    input [3:0] add_value,    // 4-bit number added each clock
    output [31:0] count
);

    wire [31:0] adder_out;    // Wire connecting adder to counter

    // Instantiate Adder
    adder_32_4 ADDER (
        .A(count),            // Current counter value
        .B(add_value),        // 4-bit input
        .Sum(adder_out)       // Output to counter
    );

    // Instantiate Counter
    counter32 COUNTER (
        .clk(clk),
        .reset(reset),
        .next_value(adder_out),
        .count(count)
    );

endmodule
