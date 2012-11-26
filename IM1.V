// Program or Instuction Memory
// Program 1
// It multiplies 3 x 5, repeatedly
//
module IM(idata,iaddr);

output [16:0] idata; // This is the instruction
input  [15:0] iaddr; // This is the address

reg    [16:0] idata;

always @(iaddr[3:1])
  case(iaddr[3:1])
     0: idata={4'd6, 3'd0, 3'd2,7'd3};  	  //L0: addi $2,$0,3
     1: idata={4'd0, 3'd0, 3'd0,3'd3, 4'd0}; //    add  $3,$0,$0
     2: idata={4'd5, 3'd2, 3'd0,7'b1111101}; //L1: beq  $2,$0,L0
     3: idata={4'd6, 3'd3, 3'd3,7'd5};       // 	   addi $3,$3,5
     4: idata={4'd6, 3'd2, 3'd2,7'b1111111}; //    addi $2,$2,-1
     5: idata={4'd8, 13'd2};                 //    j    L1
     default: idata=0;
  endcase

endmodule