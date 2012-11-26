// EE 361 Controller file for PMIPSL0
// 
// This includes Controller, which is incomplete.  It is
// a sequential circuit
//
// Notice that the ports in module are listed
// as follows:  output ports, clock (if any),
// then input ports.
// This helps to keep things straight, especially
// when modules are instatiated in other
// modules.  This convention is used throughout
// all my examples.
//

module Control(
	PCControl, // Control signals to PC circuitry
	RegWrite,
	RegDst,
	ALUSrc,
	ALU_Select, // Select to the ALU
	Branch,
	Jump,
	MemWrite,
	MemRead,
	MemtoReg,
	clock,	// Clock input signal
	OpCode,	// Opcode from the IF/ID pipeline register
	reset		// Used to clear controller
	);

output [1:0] PCControl;		
output RegWrite;
output RegDst;
output ALUSrc;
output [2:0] ALU_Select;
output Branch;
output Jump;
output MemWrite;
output MemRead;
output MemtoReg;
input  clock;
input  [3:0] OpCode;		
input  reset;		


reg [1:0] PCControl;
reg RegWrite;
reg RegDst;
reg ALUSrc;
reg [2:0] ALU_Select;
reg Branch;
reg Jump;
reg MemWrite;
reg MemRead;
reg MemtoReg;

// The controller is sequential circuit with four states.
// It starts at state 0 and proceeds to states 1, 2, and 3. Then
// it goes back to state 0.  It's basically a 2-bit counter

reg [1:0] state;	

always @(posedge clock)  // Update state
	begin
	if (reset == 1) state <= 0;
	else
		case(state)
			0: state <= 1;
			1: state <= 2;
			2: state <= 3;
			default: state <= 0;
		endcase
	end

// The output of the Controller will depend on the state.
//
// State 0:  Instruction Fetch
//			o  Increment PC
//			o  Insert bubble into the pipeline at the
//				ID/EX register
//			* Note: At the end of this clock period
//				the instruction is in the IF/ID register
//				and PC is incremented by 2
// State 1:  Instruction Decode
//			o  Stall PC
//			o  Set outputs of the controller depending
//				on the opcode field from IF/ID register
//			* Note:  At the end of this clock period
//				the control signals are in the ID/EX reg
// State 2:  Execute
//			o  Stall PC
//			o  Insert bubble into the pipeline at the
//				ID/EX register
//			* Note:  At the end of this clock period
//				the control signals are in the EX/MEM reg
//				Also in the EX/MEM reg is the branch
//				target address, jump address, ALU output,
//				and ALUzero.
// State 3:  Memory access
//			o Stall PC (but allow the PC to load in case
//				of a branch or jump).  This is referred to
//				as Conditional Load
//			o Insert bubble into the pipeline at the
//				ID/EX reg
//
// We partition the control outputs into two sets:
//	(i) controlling	the PC and (ii) controlling the rest of 
//	the datapath.  This is
//	implemented with two "always" statements.
//

// The next always statement controls the PC.  It assumes
// that the PC can
//
//	o Stall, which means it holds its value
//	o Inc, which means PC = PC+2
//	o CondLoad (Conditional Load), which means 
//		PC = 	jump address, if the instruction is jump
//			branch address, if instr is branch taken
//			PC holds value, otherwise
//
//  Note that Inc occurs at state 0, Stall occurs in states
//  1 and 2, and CondLoad occurs in state 3.
//
// The PC should have a control input PCControl connected to
// the Controller that allows the Controller to affect a Stall,
// Inc, or CondLoad.  We use the following encoding:
//
//   PCControl 	= 0, for Stall
//			= 1, for Inc
//			= 2, for CondLoad
//
// This implies that PC must have circuitry that 
// will respond to the PCControl signals from the Controller.
// The PC must also have access to the jump address and target
// branch address that come from the Memory Access stage.
// In addition, the Memory Access stage must provide to the
// PC circuitry signals indicating whether a jump will be taken
// or a branch will be taken.
//
always @(state)
	case (state)
		0: PCControl = 1;
		1: PCControl = 0;
		2: PCControl = 0;
		3: PCControl = 2;
	endcase

// This "always" statement takes care of the rest of the
// control outputs.  Note that state 1 has outputs that
// that depend on the opcode, but all other states insert
// bubbles into the pipeline.
always @(state)
	begin 
	if (state == 1)// Instruction Decode
		begin
		case(OpCode)
		0:	begin // opcode for add is 0
			RegWrite = 1;
			RegDst = 1;   // 2nd register field
			ALUSrc = 0;   // Use sign extended constant
			ALU_Select = 0;    // Add
			Branch = 0; 
			Jump = 0;
			MemWrite = 0; // No access to memory
			MemRead = 0;
			MemtoReg = 0; // Write reg file from ALU
			end
		1:	begin // opcode for sub is 1
			RegWrite = 1;
			RegDst = 1;   // 2nd register field
			ALUSrc = 0;   // Use sign extended constant
			ALU_Select = 1;    // Sub
			Branch = 0; 
			Jump = 0;
			MemWrite = 0; // No access to memory
			MemRead = 0;
			MemtoReg = 0; // Write reg file from ALU
			end
//		2:	begin // opcode for slt is 2
//			RegWrite = 1;
//			RegDst = 1;   // 2nd register field
//			ALUSrc = 0;   // Use sign extended constant
//			ALU_Select = 2;    // Add
//			Branch = 0; 
//			Jump = 0;
//			MemWrite = 0; // No access to memory
//			MemRead = 0;
//			MemtoReg = 0; // Write reg file from ALU
//			end
		3:	begin // opcode for lw is 3
			RegWrite = 1;
			RegDst = 0;
			ALUSrc = 1; 
			ALU_Select = 0;
			Branch = 0; 
			Jump = 0;
			MemWrite = 0; // No access to memory
			MemRead = 1;  // Read from memory
			MemtoReg = 1; // Loading from memory to reg
			end
		4:	begin // opcode for sw is 4
			RegWrite = 1;
			RegDst = 0;   // don't care
			ALUSrc = 1;
			ALU_Select = 0;
			Branch = 0; 
			Jump = 0;
			MemWrite = 1; // Storing to memory
			MemRead = 0;
			MemtoReg = 0;
			end

		5:	begin // opcode for beq is 5
			RegWrite = 0;
			RegDst = 0;   // don't care
			ALUSrc = 0;   // Use sign extended constant
			ALU_Select = 1;    // Subtract to check if equal zero
			Branch = 1; 
			Jump = 0;
			MemWrite = 0; // No access to memory
			MemRead = 0;
			MemtoReg = 0; // don't care
			end
		6:	begin // opcode for addi is 6
			RegWrite = 1;
			RegDst = 0;   // 2nd register field
			ALUSrc = 1;   // Use sign extended constant
			ALU_Select = 0;    // Add
			Branch = 0; 
			Jump = 0;
			MemWrite = 0; // No access to memory
			MemRead = 0;
			MemtoReg = 1; // Write reg file from ALU
			end
		default:
			begin
			RegWrite = 0;
			RegDst = 0;
			ALUSrc = 0;
			ALU_Select = 0;
			Branch = 0;
			Jump = 0;
			MemWrite = 0;
			MemRead = 0;
			MemtoReg = 0;
			end
		endcase
		end

	else // Insert bubble for all other states
		begin
		RegWrite = 0;
		RegDst = 0;
		ALUSrc = 0;
		ALU_Select = 0;
		Branch = 0;
		Jump = 0;
		MemWrite = 0;
		MemRead = 0;
		MemtoReg = 0;
		end
	end
	
endmodule
