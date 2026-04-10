`timescale 1ns / 1ps

module tb_enhanced;
    reg clk = 0;
    reg reset = 1;

    // Instantiate the processor
    risc_v_single_cycle dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("processor_test.vcd");
        $dumpvars(0, tb_enhanced);

        $monitor("Time=%0t PC=%h Reg1=%h ALU=%h", $time, dut.pc, dut.rf.regs[1], dut.alu_result);

        #10 reset = 0;  // Release reset

        #400 $finish;
    end

    // Simple assertions
    always @(posedge clk) begin
        if (reset == 0 && dut.pc_out !== 32'h4 && dut.pc_out !== 32'h8) $display("PC advanced");
    end

endmodule

