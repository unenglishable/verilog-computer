// EE 361L
// testbench for PMIPSL0
//  
// Note that the PMIPSL0.V file has an incomplete version of
// the computer.  In addition some of the signal values have
// be set to particular values.  For example, the inputs
// to the register file have been set to write the value "5"
// into register $3.  You need to replace this as you
// complete the computer design.
// 
module testbench;


wire [15:0] imemaddr; 	// Instruction memory addr
wire [15:0] dmemaddr;	// Data memory addr
wire [15:0] dmemwdata;	// Data memory write-data
wire dmemwrite;	// Data memory write enable
wire dmemread;	// Data memory read enable
wire [15:0] aluresult;	// Output from the ALU:  for debugging
wire [15:0] aluout;		// Output from the ALUOut register:  for debugging

reg  [15:0] imemrdata;	// Instruction memory read data
wire [15:0] dmemrdata;	// Data memory read data

reg  clock;
reg  reset;		// Reset

// Clock
initial clock=0;
always #1 clock=~clock;

// Test signals
// Insert instructions for testing
// You can modify it to test your computer.
// Here are other samples of instructions:
// beq $0,$0,[offset= -4] = {3'd2, 3'd0, 3'd0,7'b1111110}; Note the instruction
//      stores the constant value  -2 since the the offset is -4
// slt $4,$3,$0 = {3'd0, 3'd3, 3'd0, 3'd4, 4'd4}

initial
	begin
	imemrdata = {3'd3, 3'd0, 3'd1,7'd3};  // addi $1,$0,3
	reset = 1;
	#2
	reset = 0;
	#10
	imemrdata = {3'd3, 3'd3, 3'd1,7'd4};  // addi $1,$3,4
	#10
	imemrdata ={3'd0, 3'd3, 3'd0, 3'd4, 4'd3};  // add $4,$3,$0
	#20
	$stop;
	end
	
initial
	begin
	$display("IMem(PC,Instr),ALU(Result,Out), ALU(Clock,Reset)\n");
	$monitor("PC(%d,%d) ALU(%d,%d) [%b,%b] ",
		imemaddr,
		imemrdata,
		aluresult,
		dmemaddr,
		clock,
		reset);
	end

// Instantiation of processor

	
PMIPSL0 comp(
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


// Instantiation of Data Memory

wire io_sw0;
wire io_sw1;
wire [6:0] io_display;

assign io_sw0 = 0;
assign io_sw1 = 1;


DMemory_IO datamemdevice(
		dmemrdata,	// read data
		io_display,	// IO port connected to 7 segment display
		clock,		// clock
		dmemaddr,	// address
		dmemwdata,	// write data
		dmemwrite,	// write enable
		dmemread,	// read enable
		io_sw0,		// IO port connected to sliding switch 0
		io_sw1		// IO port connected to sliding switch 1
		);


endmodule