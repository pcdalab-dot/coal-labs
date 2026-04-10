module pc(input clk, input reset, input [31:0] next_pc, output reg [31:0] pc_out);
always @(posedge clk or posedge reset) begin
    if (reset)
        pc_out <= 0;
    else
        pc_out <= next_pc;
end
endmodule

module instruction_memory(input [31:0] addr, output [31:0] instruction);

reg [31:0] mem [0:255];

initial begin
    $readmemb("instructions.mem", mem); // load binary instructions
end

assign instruction = mem[addr[9:2]]; // word aligned

endmodule

module register_file(
    input clk,
    input regWrite,
    input [4:0] rs1, rs2, rd,
    input [31:0] writeData,
    output [31:0] readData1, readData2
);

reg [31:0] regs [0:31];

assign readData1 = regs[rs1];
assign readData2 = regs[rs2];

always @(posedge clk) begin
    if (regWrite && rd != 0)
        regs[rd] <= writeData;
end

endmodule

module alu(
    input [31:0] a, b,
    input [3:0] alu_control,
    output reg [31:0] result,
    output zero
);

always @(*) begin
    case (alu_control)
        4'b0000: result = a & b;   // AND
        4'b0001: result = a | b;   // OR
        4'b0010: result = a + b;   // ADD
        4'b0110: result = a - b;   // SUB
        default: result = 0;
    endcase
end

assign zero = (result == 0);

endmodule

module data_memory(
    input clk,
    input memRead, memWrite,
    input [31:0] addr,
    input [31:0] writeData,
    output [31:0] readData
);

reg [31:0] mem [0:4095]; // 4096 words = 16KB

assign readData = (memRead) ? mem[addr[13:2]] : 0;

always @(posedge clk) begin
    if (memWrite)
        mem[addr[13:2]] <= writeData;
end

endmodule

module control_unit(
    input [6:0] opcode,
    output reg RegWrite, MemRead, MemWrite, ALUSrc, Branch,
    output reg [1:0] ALUOp
);

always @(*) begin
    case (opcode)
        7'b0110011: begin // R-type
            RegWrite = 1; MemRead = 0; MemWrite = 0;
            ALUSrc = 0; Branch = 0; ALUOp = 2'b10;
        end
        7'b0000011: begin // lw
            RegWrite = 1; MemRead = 1; MemWrite = 0;
            ALUSrc = 1; Branch = 0; ALUOp = 2'b00;
        end
        7'b0100011: begin // sw
            RegWrite = 0; MemRead = 0; MemWrite = 1;
            ALUSrc = 1; Branch = 0; ALUOp = 2'b00;
        end
        7'b1100011: begin // beq
            RegWrite = 0; MemRead = 0; MemWrite = 0;
            ALUSrc = 0; Branch = 1; ALUOp = 2'b01;
        end
        default: begin
            RegWrite = 0; MemRead = 0; MemWrite = 0;
            ALUSrc = 0; Branch = 0; ALUOp = 2'b00;
        end
    endcase
end

endmodule

module alu_control(
    input [1:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,
    output reg [3:0] alu_ctrl
);

always @(*) begin
    case (ALUOp)
        2'b00: alu_ctrl = 4'b0010; // ADD (lw, sw)
        2'b01: alu_ctrl = 4'b0110; // SUB (beq)
        2'b10: begin
            case ({funct7, funct3})
                {7'b0000000,3'b000}: alu_ctrl = 4'b0010; // add
                {7'b0100000,3'b000}: alu_ctrl = 4'b0110; // sub
                {7'b0000000,3'b111}: alu_ctrl = 4'b0000; // and
                {7'b0000000,3'b110}: alu_ctrl = 4'b0001; // or
                default: alu_ctrl = 4'b0000;
            endcase
        end
    endcase
end

endmodule

module imm_gen(input [31:0] instr, output reg [31:0] imm);

always @(*) begin
    case (instr[6:0])
        7'b0000011: // lw (I-type)
            imm = {{20{instr[31]}}, instr[31:20]};
        7'b0100011: // sw (S-type)
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        7'b1100011: // beq (B-type)
            imm = {{19{instr[31]}}, instr[31], instr[7],
                   instr[30:25], instr[11:8], 1'b0};
        default:
            imm = 0;
    endcase
end

endmodule

module risc_v_single_cycle(input clk, input reset);

wire [31:0] pc, next_pc, instruction;
wire [31:0] readData1, readData2, writeData, imm;
wire [31:0] alu_in2, alu_result, mem_data;
wire zero;

wire RegWrite, MemRead, MemWrite, ALUSrc, Branch;
wire [1:0] ALUOp;
wire [3:0] alu_ctrl;

// PC
pc pc0(clk, reset, next_pc, pc);

// Instruction Memory
instruction_memory im(pc, instruction);

// Control Unit
control_unit cu(instruction[6:0], RegWrite, MemRead, MemWrite, ALUSrc, Branch, ALUOp);

// Register File
register_file rf(clk, RegWrite, instruction[19:15], instruction[24:20],
                 instruction[11:7], writeData, readData1, readData2);

// Immediate Generator
imm_gen ig(instruction, imm);

// ALU Control
alu_control ac(ALUOp, instruction[31:25], instruction[14:12], alu_ctrl);

// ALU Input MUX
assign alu_in2 = (ALUSrc) ? imm : readData2;

// ALU
alu alu0(readData1, alu_in2, alu_ctrl, alu_result, zero);

// Data Memory
data_memory dm(clk, MemRead, MemWrite, alu_result, readData2, mem_data);

// Write Back MUX
assign writeData = (MemRead) ? mem_data : alu_result;

// PC Logic
assign next_pc = (Branch && zero) ? pc + imm : pc + 4;

endmodule

module tb;

reg clk = 0;
reg reset = 1;

risc_v_single_cycle uut(clk, reset);

always #5 clk = ~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    #10 reset = 0;

    #200 $finish;
end

endmodule