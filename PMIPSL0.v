

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

reg	[31:0] PC; 
wire [31:0] PCPlus2;

        // Set these port values since the datapath is
assign dmemwdata = 0; // incomplete.  You should replace these.
assign dmemwdata = 0;
assign dmemwrite = 0;
assign dmemread = 0;

 //    --- Variables in the IF/ID pipeline register ---
reg [16:0] IFIDInstr; 
reg [15:0] IFIDPCPlus2;
wire [3:0] IFIDOpcode;
wire [2:0] IFIDRegfield1;
wire [2:0] IFIDRegfield2;
wire [2:0] IFIDRegfield3;
wire [6:0] IFIDConst;

//     --- Variables in the ID stage ---
wire RegWriteStub; //** Variable you should delete later.

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
wire [1:0] ALU_Select;
wire Branch;
wire Jump;
wire MemWrite;
wire MemRead;
wire MemtoReg;

 //  --- Variables in the ID/EX pipeline register ---
reg [15:0] IDEXPCPlus2; 
reg [15:0] IDEXRegRead1;
reg [15:0] IDEXRegRead2;
reg [16:0] IDEXInstr;
reg [15:0] IDEXSignExtend;
reg IDEXALUSrc;
reg [2:0] IDEXALU_Select;

//   --- Variables in the EX stage ---
wire [15:0] alusrc2;
wire [15:0] aluout1;
wire aluzero;
wire [2:0] aluselect;

//   --- Variables in the EX/MEM pipeline register ---
reg [15:0] EXMEMALUOut;
reg EXMEMALUZero;


// ***** Logic at each stage of the pipeline *****

//---- IF Stage and PC logic --------------------


assign PCPlus2 = PC + 2; // This is the adder circuit near the PC

always @(posedge clock)
	begin
	if (reset==1) 	PC <= 0;
	else 			PC <= PCPlus2;
	end

assign imemaddr = PC; // PC = instruction memory address

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
assign IFIDRegfield3 = IFIDInstr[6:4];
assign IFIDConst = IFIDInstr[6:0];

//--- ID Stage ----------

// Since the datapath is incomplete, the next three
// lines are used to set inputs of the reg file.
// You should replace this in your final implementation.
// Note that these lines will set register $3 to the
// value 5

assign waddr = 3;  
assign wdata = 5;
assign RegWriteStub = 1;
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
	RegWriteStub	// write enable
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
	clock,			
	IFIDOpcode,	// from the IFID pipeline register
	reset			
	);


//---- ID/EX Pipeline Register --------


always @(posedge clock)
	begin
	IDEXPCPlus2 <= IFIDPCPlus2;
	IDEXRegRead1 <= rdata1;
	IDEXRegRead2 <= rdata2;
	IDEXInstr <= IFIDInstr; // I probably don't need the instruction but just in case
	IDEXSignExtend <= IDSignExt;
	IDEXALU_Select <= ALU_Select;
	end


//---- EX Stage --------

MUX2 alumux( // ALU multiplexer
	alusrc2,		
	IDEXRegRead2,	
	IDEXSignExtend,	
	IDEXALUSrc		
	);	

ALU alu1(
	aluout1,	// 16-bit output from the ALU
	aluzero,	// equals 1 if the result is 0, and 0 otherwise
	IDEXRegRead1,	// data input
	alusrc2,		// data input
	aluselect		// 3-bit select
	);		

assign aluresult = aluout1; // Connect the alu with the outside world

//------ EX/MEM pipeline register ---


always @(posedge clock)
 	begin
	EXMEMALUOut <= aluout1;
	EXMEMALUZero <= aluzero;
	end


//------- MEM Stage ----------------

assign dmemaddr = EXMEMALUOut;


//------- MEM/WB pipeline register ----


//------- WB Stage ------------------
	
endmodule
