// Single Cycle MIPS
//=========================================================
// Input/Output Signals:
// positive-edge triggered         clk
// active low asynchronous reset   rst_n
// instruction memory interface    IR_addr, IR
// output for testing purposes     RF_writedata  
//=========================================================
// Wire/Reg Specifications:
// control signals             MemToReg, MemRead, MemWrite, 
//                             RegDST, RegWrite, Branch, 
//                             Jump, ALUSrc, ALUOp
// ALU control signals         ALUctrl
// ALU input signals           ALUin1, ALUin2
// ALU output signals          ALUresult, ALUzero
// instruction specifications  r, j, jal, jr, lw, sw, beq
// sign-extended signal        SignExtend
// MUX output signals          MUX_RegDST, MUX_MemToReg, 
//                             MUX_Src, MUX_Branch, MUX_Jump
// registers input signals     Reg_R1, Reg_R2, Reg_W, WriteData 
// registers                   Register
// registers output signals    ReadData1, ReadData2
// data memory contral signals CEN, OEN, WEN
// data memory output signals  ReadDataMem
// program counter/address     PCin, PCnext, JumpAddr, BranchAddr
//=========================================================

module SingleCycle_MIPS( 
    clk,
    rst_n,
    IR_addr,
    IR,
    RF_writedata,
    ReadDataMem,
    CEN,
    WEN,
    A,
    ReadData2,
    OEN
);

//==== in/out declaration =================================
    //-------- processor ----------------------------------
    input         clk, rst_n;
    input  [31:0] IR;
    output [31:0] IR_addr, RF_writedata;
    //-------- data memory --------------------------------
    input  [31:0] ReadDataMem;  // read_data from memory
    output        CEN;  // chip_enable, 0 when you read/write data from/to memory
    output        WEN;  // write_enable, 0 when you write data into SRAM & 1 when you read data from SRAM
    output  [6:0] A;  // address
    output [31:0] ReadData2;  // write_data to memory
    output        OEN;  // output_enable, 0

//==== reg/wire declaration ===============================

    // control signals             
    wire            RegDST, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump;
    wire[1:0]       ALUOp;
    // ALU control signals         
    wire[3:0]       ALUctrl;
    // ALU input signals           
    wire[31:0]      ALUin1, ALUin2;
    // ALU output signals          
    reg[31:0]       ALUresult;
    reg             ALUzero;
    // sign-extended signal        
    wire[31:0]      SignExtend;
    // MUX output signals          
    wire            MUX_RegDST, MUX_MemToReg, 
                    MUX_Src, MUX_Branch, MUX_Jump;
    // registers input signals     
    wire[4:0]       Reg_R1, Reg_R2, Reg_W, WriteData;
    // registers                   
    reg[31:0]       Register[31:0];
    // registers out    put signals    
    wire[31:0]      ReadData1;
    // data memory contral signals 
    wire            CEN, OEN, WEN;
    // program counter/address     
    reg[31:0]       PCin;
    reg[31:0]       PCnext, JumpAddr, BranchAddr;
    reg[31:0]       IR_addr, RF_writedata;

//==== combinational part =================================

// control unit
    localparam R    = 6'b000000;
    localparam J    = 6'b000010;
    localparam JAL  = 6'b000011;
    localparam JR   = 6'b000000;
    localparam LW   = 6'b100011;
    localparam SW   = 6'b101011;
    localparam BEQ  = 6'b000100;

    wire[5:0] OpCode = IR[31:26];

    assign RegDst   = (OpCode == R);
    assign ALUSrc   = (OpCode == LW | OpCode==SW);
    assign MemtoReg = (OpCode == LW);
    assign RegWrite = (OpCode == R | OpCode == LW);
    assign MemRead  = (OpCode == LW);
    assign MemWrite = (OpCode == SW);
    assign Branch   = (OpCode == BEQ);
    assign ALUOp[0] = (OpCode == BEQ);
    assign ALUOp[1] = (OpCode == R);
    assign RegDST   = (OpCode == R);
    assign Jump     = (OpCode == J | OpCode==JAL);

    // alu control
    wire[5:0] FnCode = IR[5:0];

    assign ALUctrl[3] = ( (ALUOp[1] & ~ALUOp[0]) & FnCode==6'b100111 ); // nor
    assign ALUctrl[2] = ( (ALUOp[1] & ~ALUOp[0]) & (FnCode==6'b100111 | FnCode==6'b101010 | FnCode==6'b100010) | (~ALUOp[1] & ALUOp[0]) ); // nor, slt, sub, beq
    assign ALUctrl[1] = ( (ALUOp[1] & ~ALUOp[0]) & (FnCode==6'b100111 | FnCode==6'b101010 | FnCode==6'b100010 | FnCode==6'b100000) | (~ALUOp[1] & ALUOp[0]) ) | ~(ALUOp[1] & ~ALUOp[0]); // nor, slt, sub, add, beq, lw, sw
    assign ALUctrl[0] = ( (ALUOp[1] & ~ALUOp[0]) & (FnCode==6'b101010 | FnCode==6'b100101) ); // slt, or




// alu
    assign SignExtend = { {16{IR[15]}}, IR[15:0] };
    assign ALUin1 = ReadData1;
    assign ALUin2 = ALUSrc ? SignExtend : ReadData2;

    always @(ALUctrl or ALUin1 or ALUin2)
    begin
        case(ALUctrl)
            4'b0000: begin ALUzero=1'b0; ALUresult=ALUin1&ALUin2; end
            4'b0001: begin ALUzero=1'b0; ALUresult=ALUin1|ALUin2; end
            4'b0010: begin ALUzero=1'b0; ALUresult=ALUin1+ALUin2; end
            4'b0110: begin if(ALUin1==ALUin2) ALUzero=1'b1; else ALUzero=1'b0; ALUresult=ALUin1-ALUin2; end
            4'b0111: begin ALUzero=1'b0; if(ALUin1-ALUin2>=32'h8000_0000) ALUresult=32'b1; else ALUresult=32'b0; end
            4'b1100: begin ALUzero=1'b0; ALUresult=(~ALUin1|~ALUin2); end
            default: begin ALUzero=1'b0; ALUresult=ALUin1; end
        endcase
    end




// pc
    always @(*)
    begin
        PCin        = IR_addr;
        PCnext      = PCin+4;
        JumpAddr    = { PCnext[31:28], IR[25:0]<<2 };
        BranchAddr  = { {16{IR[15]}}, IR[15:0]};
    end
        



// register file
    assign Reg_R1 = IR[25:21]; // rs
    assign Reg_R2 = IR[20:16]; // rt
    assign Reg_W = RegDst ? IR[15:11] : IR[20:16]; // rd or rt
    assign ReadData1 = Register[Reg_R1];
	assign ReadData2 = Register[Reg_R2];


// mem
    assign A = ALUresult[8:2];
    
    assign CEN = OpCode==LW ? 0 : 1;
    assign OEN = OpCode==LW ? 0 : 1;
    assign WEN = OpCode==LW ? 1 : 0;
    always @(*)
    begin
        if(OpCode==LW)
            RF_writedata <= ReadDataMem;
        else
            RF_writedata <= ALUresult;
    end



//==== sequential part ====================================

// pc
    always @ (posedge clk or negedge rst_n)
	begin
        if(~rst_n)
            IR_addr <= 0;
        else 
            IR_addr <= PCnext;
	end

// register file
    integer i;
    always @ (posedge clk or negedge rst_n)
	begin
        // Register[Reg_W] <= RegWrite ? WriteData : Register[Reg_W];
        if(~rst_n)
        begin
            for(i=0; i<32; i=i+1)
            begin
                Register[i] = 0;
            end
        end
        else
        begin
            $monitor("m: IR=%b, ReadData1=%b, ReadData2=%b, Register[Reg_W]=%b",IR, ReadData1, ReadData2, Register[8]);
            if(OpCode==LW)
                Register[Reg_W] <= ReadDataMem;
            else
                Register[Reg_W] <= ALUresult;
        end
	end

//=========================================================
endmodule
