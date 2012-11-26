// 16-bit MIPS Parts
// 
// * Data Memory and IO:  This is the data memory, and some IO hardware
// * 8x16 register file:  eight 16-bit registers
// * 16-bit ALU
// * 2:1 16-bit Multiplexer
// * Sign extender from 7 to 16 bits
// * 4:1 16-bit Multiplexer

//----------------------------------------------------------
// Data Memory and IO
// The data memory is 128 16-bit words.  The addresses are
// 0, 2, 4, ...., 254.  Note that the address of words are 
// divisible by 2 (memory is byte addressable and big endian).
// This module also has some hardware for IO.  In particular,
// There are three ports:
//
//     Address	Type		What's it connected to
//     0xfff8	Output		Seven segment display
//     0xfffa	Output		LED
//     0xfffe	Input		Sliding Switches
//
// Output port 0xfffa is connected to an 7-bit register. So
// when storing a word "w" to the port, the value
// w[6:0] gets stored in the port's register.  The output
// of this register is connected to a seven segment display.
// The display has pin names
//
//    -a-
//   f   b
//    -g-
//   e   c
//    -d-
//
// and (a,b,c,d,e,f,g) = (w[6],w[5],....w[0]).  For example,
// to display the number "5", then w = (1,0,1,1,0,1,1).
//
// The input port 0xfff0 is connected to sliding switches SW1,
// SW0, and pushbutton PB0.  After reading a word "w" from the port,
// the word has value w[2] = SW1, w[1] = SW0, and w[0] = PB0.
//
// 
module DMemory_IO(
		rdata,		// read data
		io_display,	// IO port connected to 7 segment display
		clock,		// clock
		addr,		// address
		wdata,		// write data
		write,		// write enable
		read,		// read enable
		io_sw0,		// IO port connected to sliding switch 0
		io_sw1		// IO port connected to sliding switch 1
		);
		

output [15:0] rdata;
output [6:0] io_display;
input clock;
input [15:0] addr;
input [15:0] wdata;
input write;
input read;
input io_sw0;
input io_sw1;

reg [15:0] memcell[0:127]; // 128 words = 256 bytes, so address 0, 1, ...., 255

reg [15:0] rdata;
wire [15:0] mem_rdata;	// Output of data memory
wire [15:0] io_rdata;   // Input from io port fffe, which is connected to
						//   sliding switches SW1 and SW0 through bits 1 and 0,
						//   respectively

reg [6:0] io_display; // seven segment display

// Output of data memory
assign mem_rdata = memcell[addr[7:1]]; // Only need bits 6, 5, ..., 1 of the address

// The io port of the sliding switches.  Last two bits are the sliding switches
// SW1 and SW0 as bits 1 and 0, respectively.
assign io_rdata = {14'd0,io_sw1,io_sw0};

// This is basically a multiplexer, that chooses to output the
// memory or IO.  If data memory is being accessed then the
// address is between 0 and 255.  If the address is 0xfff0 then
// the io port is being accessed.  This io port is connected to
// the sliding switches SW1 and SW0 at bits 1 and 0, respectively.
always @(addr or mem_rdata or io_rdata or read)
	begin
	if (read == 0) rdata = 0;
	else // read = 1
		begin
		if (addr >= 0 && addr < 256) 	rdata = mem_rdata; 
		else if (addr == 16'hfff0) 		rdata = io_rdata;
		else rdata = 0; // default 
		end
	end

// IO port fffa that is connected to the seven segment display.
// This loads the port register.
always @(posedge clock)
	if (write == 1 && addr == 16'hfffa) io_display <= wdata[6:0];

// Note that if waddr[15:0] = 0 then 0 <= waddr < 256 and one of the
// 256 memory cells is being accessed
always @(posedge clock)
	if (write == 1 && addr[15:8] == 0) memcell[addr[7:1]] <= wdata;

endmodule

//----------------------------------------------------------
// 8x16 Register File
module RegFile(
	rdata1,			// read data output 1
	rdata2,			// read data output 2
	clock,		
	wdata,			// write data input
	waddr,			// write address
	raddr1,			// read address 1
	raddr2,			// read address 2
	write			// write enable
	);			

output [15:0] rdata1, rdata2;
input clock;
input [15:0] wdata; 			

input [2:0] raddr1, raddr2; 	
input [2:0] waddr; 			
input write;					

reg [15:0] rdata1, rdata2;

reg [15:0] regcell[0:7];		// Eight registers

// Writing to a register
always @(negedge clock) if (write==1) regcell[waddr]<=wdata;

// Reading from a register
always @(raddr1 or regcell[raddr1]) 
	if (raddr1 == 0) 	rdata1 = 0;
	else 				rdata1 = regcell[raddr1];

// Reading from a register
always @(raddr2 or regcell[raddr2]) 
	if (raddr2 == 0) 	rdata2 = 0;
	else 				rdata2 = regcell[raddr2];

endmodule

//----------------------------------------------------------
// ALU
// 
// Function table
// select	function

// 0		add
// 1		subtract
// 2		slt
// 3		or
// 4		and
//
module ALU(
	result,			// 16-bit output from the ALU
	zero_result,	// equals 1 if the result is 0, and 0 otherwise
	indata0,		// data input
	indata1,		// data input
	select			// 3-bit select
	);		

output [15:0] result;
output zero_result;
input [15:0] indata0, indata1;
input [2:0] select;


reg [15:0] result;
reg zero_result;

always @(indata0 or indata1 or select)
	case(select)
	0: result = indata0 + indata1;
	1: result = indata0 - indata1;
	2: result = (indata0 - indata1) >> 15;
	3: result = indata0 | indata1;
	4: result = indata0 & indata1;
	default: result = 0;
	endcase
	
always @(result) // This is basically a NOR operation
	if (result == 0) 	zero_result = 1;
	else 			  	zero_result = 0;

endmodule

//----------------------------------------------------------
// 2:1 Multiplexer

module MUX2(
	result,		// Output of multiplexer
	indata0,	// Input 0
	indata1,	// Input 1
	select		// 1-bit select
	);	

output [15:0] result;
input [15:0] indata0, indata1;
input select;

reg [15:0] result;

always @(indata0 or indata1 or select)
	case(select)
	0: result = indata0;
	1: result = indata1;
	endcase

endmodule

//----------------------------------------------------------
// 4:1 Multiplexer
module MUX4(
	result,		// 16 bit output
	indata0,	// Input 0
	indata1,	// Input 1
	indata2,	// Input 2
	indata3,	// Input 3
	select		// 2-bit select input
	);	

output [15:0] result;
input [15:0] indata0, indata1, indata2, indata3;
input [1:0] select;

reg [15:0] result;

always @(indata0 or indata1 or indata2 or indata3 or select)
	case(select)
	0: result = indata0;
	1: result = indata1;
	2: result = indata2;
	3: result = indata3;
	endcase

endmodule

//----------------------------------------------------------
// Sign Extension from 7 bits to 16
module SignExt(
	result,		// 16 bit sign extended result
	value		// 7 bit twos complement input
	);		

output [15:0] result;
input [6:0] value;

assign result = {{9{value[6]}},value }; // Repeat sign bit eight times.
	// Note that that the repetition has to be within parentheses.
	// For example { 9{value[6]}, value} won't work because
	// 9{value[6]} is incorrect.  This can be fixed by using
	// {9{value[6]}}

endmodule

