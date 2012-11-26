// Testbench for the Controller circuit for PMIPSL0
// This is a simple one
module testbench;


// We need to insert input signals to the Controller

// We'll use register variables
reg clock;
reg [3:0] Opcode;
reg reset;

// We'll probe the outputs of the controller with wire variables

wire [1:0] PCControl;			
wire RegWrite;
wire RegDst;
wire ALUSrc;
wire ALUOp;
wire Branch;
wire Jump;
wire MemWrite;
wire MemRead;
wire MemtoReg;

// Generate clock signal

initial clock = 0;
always #1 clock = ~clock; // Clock period = 2 time units

// Instantiation of the controller

Control control1(
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
	clock,	// Clock input signal
	Opcode,	// Opcode from the IF/ID pipeline register
	reset		// Used to clear controller
	);

// The following generates input signals to the controller
initial
	begin
	reset = 1;
	Opcode = 6; // opcode for addi
	#2			// delay one clock cycle
	reset = 0;
	#20			// delay 10 clock cycles
	$stop;
	end
	

initial
	begin
	$display("PC(PCControl),Reg(Wr,Dst,MemtoReg), ALU(Src,Op), Mem(Wr,Rd), Br(Br), Jmp(J), [Clk,Rst,Op]\n");
	$monitor("PC(%b) Reg(%b,%b,%b) ALU(%b,%d) Mem(%b,%b) Br(%b) J(%b) [%b,%b,%d]",
		PCControl,				
		RegWrite,
		RegDst,
		MemtoReg,
		ALUSrc,
		ALUOp,
		MemWrite,
		MemRead,
		Branch,
		Jump,
		clock,
		reset,
		Opcode);
	end

endmodule