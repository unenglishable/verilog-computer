

// This is very incomplete

module PMIPSL0(
	imemaddr, 	// Instruction memory addr
	dmemaddr,	// Data memory addr
	dmemwdata,	// Data memory write-data
	dmemwrite,	// Data memory write enable
	dmemread,	// Data memory read enable
	aluresult,	// Output from the ALU:  for debugging
	clock,
	imemrdata,	// Instruction memory read data
	dmemrdata,	// Data memory read data
	reset		// Reset
	);

output [15:0] imemaddr;
output [15:0] dmemaddr;
output [15:0] dmemwdata;
output dmemwrite;	
output dmemread;	
output [15:0] aluresult;	
input clock;
input [16:0] imemrdata;	
input [15:0] dmemrdata;
input reset; 


// ***** Variables at each stage of the pipeline *****
//
//     --- Variables in IF stage and PC logic ---

reg	[15:0] PC; 
wire [15:0] StallMuxResult;
wire [15:0] PCMuxResult;
wire [15:0] PCPlus2;
wire Stall;
wire PCSrc;

        // Set these port values since the datapath is
		  // incomplete.  You should replace these.
		  
reg EXMEMdmemwdata;
reg EXMEMdmemwrite;
reg EXMEMdmemread;

assign dmemwdata = EXMEMdmemwdata;
assign dmemwrite = EXMEMdmemwrite;
assign dmemread = EXMEMdmemread;

//    --- Variables in the IF/ID pipeline register ---
reg [16:0] IFIDInstr; 
reg [15:0] IFIDPCPlus2;
wire [3:0] IFIDOpcode;
wire [2:0] IFIDRegfield1;
wire [2:0] IFIDRegfield2;
wire [2:0] IFIDRegfield3;
wire [6:0] IFIDConst;

//     --- Variables in the ID stage ---

wire [15:0] rdata1; // Variables connected to reg file
wire [15:0] rdata2;
wire [15:0] wdata;
wire [2:0] waddr;
wire negclock;


wire [15:0] IDSignExt; // Sign extension
                // Variables from the controller
wire [1:0] PCControl;	// Control signals to the PC logic
wire RegWrite;
wire RegDst;
wire Branch;
wire Jump;
wire MemWrite;
wire MemRead;
wire MemtoReg;
wire [2:0] ALUOp;
wire ALUSrc;

 //  --- Variables in the ID/EX pipeline register ---
// Pipelined EX
reg IDEXALUSrc;
reg [2:0] IDEXALUOp;
reg IDEXRegDst;
// Pipelined MEM
reg IDEXBranch;
reg IDEXMemWrite;
reg IDEXMemRead;
// Pipelined WB
reg IDEXRegWrite;
reg IDEXMemtoReg;

// Passed through pipelining
reg [15:0] IDEXPCPlus2; 
reg [15:0] IDEXRegRead1;
reg [15:0] IDEXRegRead2;
reg [15:0] IDEXSignExtend;

// Sasaki added, might not need
reg [16:0] IDEXInstr;

// For RegDst Mux
reg [2:0] IDEXRegfield2; // rt
reg [2:0] IDEXRegfield3; // rd

//   --- Variables in the EX stage ---
wire [15:0] alusrc2;
wire [15:0] aluout1;
reg [15:0] addResult;
wire [15:0] shiftLeft1;
wire aluzero;

reg [2:0] RegDstMuxResult;

//   --- Variables in the EX/MEM pipeline register ---
// Pipelined MEM
reg EXMEMBranch;
reg EXMEMMemWrite;
reg EXMEMMemRead;
// Pipelined WB
reg EXMEMRegWrite;
reg EXMEMMemtoReg;

// Passed through pipelining
reg [15:0] EXMEMALUOut;
reg EXMEMALUZero;
reg [15:0] EXMEMAddResult;
reg [15:0] EXMEMRegRead2;
reg [2:0] EXMEMwaddr;

//   --- Variables in the MEM stage ---

	//NOTHING HERE

//   --- Variables in the MEM/WB pipeline register ---
// Pipelined WB
reg MEMWBRegWrite;
reg MEMWBMemtoReg;
reg [15:0] MEMWBdmemrdata;
reg [15:0] MEMWBALUOut;
reg [2:0] MEMWBwaddr;

//   --- Variables in the MEM stage ---
reg [15:0] WBMuxResult;


// ***** Logic at each stage of the pipeline *****

//---- IF Stage and PC logic --------------------

assign PCPlus2 = PC + 2; // This is the adder circuit near the PC

MUX2 stallMux(StallMuxResult,PCPlus2,PC,Stall);
MUX2 pcMux(PCMuxResult,StallMuxResult,EXMEMAddResult,PCSrc);

always @(posedge clock)
	begin
	if (reset==1) 	PC <= 0;
	else 			PC <= PCMuxResult;
	end

assign imemaddr = PC; // PC = instruction memory address

//---- IF/ID Pipeline Register --------

always @(posedge clock)
	begin
	if (reset == 1)
		begin
		IFIDInstr <= 0;
		IFIDPCPlus2 <= 0;
		end
	else
		begin
		IFIDPCPlus2 <= PCPlus2;
		IFIDInstr <= imemrdata;
		end
	end

assign IFIDOpcode = IFIDInstr[16:13];
assign IFIDRegfield1 = IFIDInstr[12:10];
assign IFIDRegfield2 = IFIDInstr[9:7];
assign IFIDRegfield3 = IFIDInstr[6:4];
assign IFIDConst = IFIDInstr[6:0];

//--- ID Stage ----------

// Since the datapath is incomplete, the next three
// lines are used to set inputs of the reg file.
// You should replace this in your final implementation.
// Note that these lines will set register $3 to the
// value 5

assign waddr = MEMWBwaddr;  
assign wdata = WBMuxResult;
assign negclock = ~clock;  // Reg file is synchronized
						   // to pos clock edge, so we
						   // supply inverted clock
						   // signal to the reg file.

 RegFile rfile1(
 	rdata1,			// read data output 1
	rdata2,			// read data output 2
	negclock,		
	wdata,			// write data input
	waddr,			// write address
	IFIDRegfield1,	// read address 1
	IFIDRegfield2,	// read address 2
	MEMWBRegWrite	// write enable
	);			

assign IDSignExt = {{9{IFIDInstr[6]}},IFIDInstr[6:0]};

Control cntrol1(
	PCControl,					
	RegWrite,
	RegDst,
	ALUSrc,
	ALUOp,
	Branch,
	Jump,
	MemWrite,
	MemRead,
	MemtoReg,
	Stall,
	clock,			
	IFIDOpcode,	// from the IFID pipeline register
	reset			
	);


//---- ID/EX Pipeline Register --------


always @(posedge clock)
	begin
	if (reset == 1)
		begin
		// Pipelined EX
		IDEXALUSrc <= 0;
		IDEXALUOp <= 0;
		IDEXRegDst <= 0;

		// Pipelined M
		IDEXBranch <= 0;
		IDEXMemRead <= 0;
		IDEXMemWrite <= 0;

		// Pipelined WB
		IDEXRegWrite <= 0;
		IDEXMemtoReg <= 0;

		// Passed through pipeling
		IDEXPCPlus2 <= 0;
		IDEXRegRead1 <= 0;
		IDEXRegRead2 <= 0;
		IDEXSignExtend <= 0;

		// Sasaki added, might not need
		IDEXInstr <= 0;

		// For MUX in Execute Stage, RegDst
		IDEXRegfield2 <= 0; // rt
		IDEXRegfield3 <= 0; // rd
		end
	else
		begin
		// Pipelined EX
		IDEXALUSrc <= ALUSrc;
		IDEXALUOp <= ALUOp;
		IDEXRegDst <= RegDst;

		// Pipelined M
		IDEXBranch <= Branch;
		IDEXMemRead <= MemRead;
		IDEXMemWrite <= MemWrite;

		// Pipelined WB
		IDEXRegWrite <= RegWrite;
		IDEXMemtoReg <= MemtoReg;

		// Passed through pipeling
		IDEXPCPlus2 <= IFIDPCPlus2;
		IDEXRegRead1 <= rdata1;
		IDEXRegRead2 <= rdata2;
		IDEXSignExtend <= IDSignExt;

		// Sasaki added, might not need
		IDEXInstr <= IFIDInstr;

		// For MUX in Execute Stage, RegDst
		IDEXRegfield2 <= IFIDRegfield2; // rt
		IDEXRegfield3 <= IFIDRegfield3; // rd
		end
	end


//---- EX Stage --------

MUX2 alumux( // ALU multiplexer
	alusrc2,	// mux output
	IDEXRegRead2,	// input 1
	IDEXSignExtend,	// input 2
	IDEXALUSrc	// select
	);	

ALU alu1(
	aluout1,	// 16-bit output from the ALU
	aluzero,	// equals 1 if the result is 0, and 0 otherwise
	IDEXRegRead1,	// data input
	alusrc2,		// data input
	IDEXALUOp		// 3-bit select
	);		

MUX2_Address RegDstMux(
	RegDstMuxResult,	// mux output
	IDEXRegfield2,		// rt
	IDEXRegfield3,		// rd
	IDEXRegDst		// select
	);

assign shiftLeft1 = IDEXSignExtend << 1;
always @(IDEXPCPlus2 or shiftLeft1)
	addResult = IDEXPCPlus2 + shiftLeft1;

assign aluresult = aluout1; // Connect the alu with the outside world

//------ EX/MEM pipeline register ---


always @(posedge clock)
 	begin
	if (reset == 1)
		begin
		// Pipelined M
		EXMEMBranch <= 0;
		EXMEMMemRead <= 0;
		EXMEMMemWrite <= 0;

		// Pipelined WB
		EXMEMRegWrite <= 0;
		EXMEMMemtoReg <= 0;

		// Passed through pipeling
		EXMEMALUOut <= 0;
		EXMEMALUZero <= 0;
		EXMEMAddResult <= 0;
		EXMEMRegRead2 <= 0;
		EXMEMwaddr <= 0;
		end
	else
		begin
		// Pipelined M
		EXMEMBranch <= IDEXBranch;
		EXMEMMemRead <= IDEXMemRead;
		EXMEMMemWrite <= IDEXMemWrite;

		// Pipelined WB
		EXMEMRegWrite <= IDEXRegWrite;
		EXMEMMemtoReg <= IDEXMemtoReg;

		// Passed through pipeling
		EXMEMALUOut <= aluout1;
		EXMEMALUZero <= aluzero;
		EXMEMAddResult <= addResult;
		EXMEMRegRead2 <= IDEXRegRead2;
		EXMEMwaddr <= RegDstMuxResult;
		end
	end


//------- MEM Stage ----------------

assign dmemaddr = EXMEMALUOut;
assign PCSrc = EXMEMALUZero && EXMEMBranch;

//------- MEM/WB pipeline register ----

always @(posedge clock)
 	begin
	if (reset == 1)
		begin
		// Pipelined WB
		MEMWBRegWrite <= 0;
		MEMWBMemtoReg <= 0;

		// Passed through pipeling
		MEMWBwaddr <= 0;
		MEMWBALUOut <= 0;
		MEMWBdmemrdata <= 0;
		end
	else
		begin
		// Pipelined WB
		MEMWBRegWrite <= EXMEMRegWrite;
		MEMWBMemtoReg <= EXMEMMemtoReg;

		// Passed through pipeling
		MEMWBwaddr <= EXMEMwaddr;
		MEMWBALUOut <= EXMEMALUOut;
		MEMWBdmemrdata <= dmemrdata;
		end
	end

//------- WB Stage ------------------

MUX2 WBMux(
	WBMuxResult,
	MEMWBdmemrdata,
	MEMWBALUOut,
	MEMWBMemtoReg
	);

endmodule
