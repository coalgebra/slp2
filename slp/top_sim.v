`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:09:26 01/03/2018
// Design Name:   Top
// Module Name:   C:/Users/zjuwyd/Desktop/New folder - Copy - Copy - Copy/New folder - Copy - Copy - Copy/top_sim.v
// Project Name:  VGAdemo
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module top_sim;

	// Inputs
	reg clk;
	reg rstn;
	reg [15:0] SW;

	// Outputs
	wire hs;
	wire vs;
	wire [3:0] r;
	wire [3:0] g;
	wire [3:0] b;
	wire SEGLED_CLK;
	wire SEGLED_CLR;
	wire SEGLED_DO;
	wire SEGLED_PEN;
	wire LED_CLK;
	wire LED_CLR;
	wire LED_DO;
	wire LED_PEN;
	wire buzzer;

	// Bidirs
	wire [4:0] BTN_X;
	wire [3:0] BTN_Y;

	// Instantiate the Unit Under Test (UUT)
	Top uut (
		.clk(clk), 
		.rstn(rstn), 
		.SW(SW), 
		.hs(hs), 
		.vs(vs), 
		.r(r), 
		.g(g), 
		.b(b), 
		.SEGLED_CLK(SEGLED_CLK), 
		.SEGLED_CLR(SEGLED_CLR), 
		.SEGLED_DO(SEGLED_DO), 
		.SEGLED_PEN(SEGLED_PEN), 
		.LED_CLK(LED_CLK), 
		.LED_CLR(LED_CLR), 
		.LED_DO(LED_DO), 
		.LED_PEN(LED_PEN), 
		.BTN_X(BTN_X), 
		.BTN_Y(BTN_Y), 
		.buzzer(buzzer)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rstn = 0;
		SW = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
	
	always begin
		clk = 0; #1;
		clk = 1; #1;
	end
      
endmodule

