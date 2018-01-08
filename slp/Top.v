`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2016/10/17 12:25:41
// Design Name:
// Module Name: Top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`define BLACK 12'b0

module Top(
	input clk,
	input rstn,
	input [15:0]SW,

	input ps2_clk,
	input ps2_data,

	output hs,
	output vs,
	output [3:0] r,
	output [3:0] g,
	output [3:0] b,
	output SEGLED_CLK,
	output SEGLED_CLR,
	output SEGLED_DO,
	output SEGLED_PEN,
    output LED_CLK,
	output LED_CLR,
	output LED_DO,
	output LED_PEN,
	inout [4:0]BTN_X,
	inout [3:0]BTN_Y,
	output buzzer
    );

	parameter START_MODE = 0;
	parameter RUN_MODE = 1;
	parameter PAUSE_MODE = 2;
	parameter FAIL_MODE = 3;
	
	parameter HORIZON_HEIGHT = 120;
	parameter BLOCKER_WIDTH = 40;
	parameter RADIUS = 40;
	parameter HORIZON_SPEED = 5;
	parameter BOMB_GEN_RANGE = 60;
	parameter BOMB_RADIUS = 32;
	parameter GIFT_RADIUS = 32;

	parameter BLOCKER_COLOR = 12'h0111_1010_1010;
	parameter HORIZON_COLOR = 12'h0111_0111_0111;

	reg [5:0] G = 6'd1;
	reg [9:0] jump_speed = 10'd12;

	reg [31:0] clkdiv;
	always@(posedge clk) begin
		clkdiv <= clkdiv + 1'b1;
	end
	assign buzzer = 1'b1;
	wire [15:0] SW_OK;
	AntiJitter #(4) a0[15:0](.clk(clkdiv[15]), .I(SW), .O(SW_OK));

	wire [4:0] keyCode;
	wire keyReady;
	Keypad k0 (.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X), .keyCode(keyCode), .ready(keyReady));

	wire [31:0] segTestData;
	wire [3:0]sout;
	Seg7Device segDevice(.clkIO(clkdiv[3]), .clkScan(clkdiv[15:14]), .clkBlink(clkdiv[25]),
		.data(segTestData), .point(8'h0), .LES(8'h0),
		.sout(sout));

	wire [7:0] key_code;
	wire key_ready;
	reg key_was_ready;

	ps2scan keyboard (
		.clk(clk),
		.rst(rstn),
		.ps2k_clk(ps2_clk),
		.ps2k_data(ps2_data),
		.ps2_byte(key_code),
		.ps2_state(key_ready)
    );

	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];

	reg [9:0] xx = 10'd120;
	reg [8:0] yy = 9'd120;



	wire move_clk;
	assign move_clk = clkdiv[19];

	reg [1:0] sugata_counter;

	reg [11:0] vga_data;
	wire [9:0] col_addr;
	wire [8:0] row_addr;

	vgac v0 (
		.vga_clk(clkdiv[1]),
		.clrn(SW_OK[0]),
		.d_in(vga_data),
		.row_addr(row_addr),
		.col_addr(col_addr),
		.r(r),
		.g(g),
		.b(b),
		.hs(hs),
		.vs(vs)
	);
	reg wasReady;

	reg [19:0] move_counter = 0;
	reg jump_counter = 0;
	reg [1:0] game_mode = START_MODE;
	reg [4:0] bg_speed = 5'd2;
	reg [9:0] speed = 0;
	reg [4:0] blocker_speed = 5'd6;
	reg speed_dir = 0;

	reg [10:0] x_offset = 0;

	reg [2:0] djmp_flag = 1;

	reg [2:0] blocker_number;
	reg [10:0] blocker_height [7:0]; // 2^15 / 8 = 2^12 ?��?????position
	reg [10:0] blocker_position [7:0];

	reg [2:0] level = 0;
	reg hor_speed_dir = 0;
	reg [10:0] hor_speed = 0;

	reg [1:0] sugata_flag;

	integer score = 0;
	integer time_counter = 0;

	reg [10:0] bomb_x;
	reg [9:0] bomb_y;

	reg [10:0] bomb_speed = 7;
	reg [11:0] bomb_stop_counter;
	reg [10:0] gift_x;
	reg [9:0]  gift_y;
	reg 		  gift_exist;
	
	wire [10:0] blocker_true_speed;
	assign blocker_true_speed = (blocker_speed + level);
	
	task gift_initialize;
		begin
			gift_exist <= 1;
			gift_x <= 640;
			gift_y <= (clkdiv % 200) + 120;
		end
	endtask
	
	task move_gift;
		begin
			if (gift_x < blocker_true_speed)
				gift_exist <= 0;
			else
				gift_x <= gift_x - blocker_true_speed;
		end
	endtask
	
	wire intersect_with_gift_flag;
	
	assign intersect_with_gift_flag = 
				(xx + RADIUS> gift_x &&
				 xx < gift_x + RADIUS + GIFT_RADIUS &&
				 yy + RADIUS > gift_y &&
				 yy < gift_y + RADIUS + GIFT_RADIUS);
	
	task bomb_initialize;
		begin 
			bomb_stop_counter <= 50;
			bomb_x <= (xx < BOMB_GEN_RANGE) 
				? ((clkdiv % (BOMB_GEN_RANGE + xx))) 
				: ((xx + RADIUS + BOMB_GEN_RANGE> 640) 
					? (clkdiv % (640 - xx + BOMB_GEN_RANGE) + xx - BOMB_GEN_RANGE)
					: (xx - BOMB_GEN_RANGE + (clkdiv % (BOMB_GEN_RANGE * 2))));
			bomb_y <= 480;
			bomb_speed <= 7 + level;
		end
	endtask

	task move_bomb;
		begin
			if (|bomb_stop_counter) 
				bomb_stop_counter <= bomb_stop_counter - 1;
			else begin
				if (bomb_y < bomb_speed + HORIZON_HEIGHT) begin
					bomb_initialize();
				end else
					bomb_y <= bomb_y - bomb_speed;
			end
		end
	endtask

	task adjust_bomb_speed;
		begin
			/*if (|bomb_stop_counter) 
				bomb_speed <= 0;
			else begin
				bomb_speed <= bomb_speed + G;
			end*/
		end
	endtask

	reg if_keyboard_ready = 0;

	task test_init_blocker;
		begin
			blocker_number <= 1;
			blocker_height[0] <= 100;
			blocker_position[0] <= 640;
		end
	endtask

	task move_blocker;
		if (blocker_position[0] < blocker_true_speed) begin
			blocker_position[0] <= 640;
			blocker_height[0] <= (clkdiv % (40 + 40 * (level / 2))) + 40 + 10 * level;
		end
		else
			blocker_position[0] <= blocker_position[0] - blocker_true_speed;
	endtask

	task move_background;
		x_offset <= (x_offset + bg_speed + (level >> 1)) % 640;
	endtask

	task reset_to_horizon;
		begin
			speed <= 0;
			speed_dir <= 0;
			yy <= HORIZON_HEIGHT;
			djmp_flag <= (1 + (level / 2));
		end
	endtask

	task move_object;
		begin
			if (speed != 0)
				if (speed_dir == 0)
					yy <= (yy + speed);
				else
					yy <= (yy - speed);
			if (hor_speed != 0)
				if (hor_speed_dir == 0)
					if (xx < hor_speed)
						xx <= 0;
					else
						xx <= xx - hor_speed;
				else
					if (xx + RADIUS + hor_speed > 640)
						xx <= 640 - RADIUS;
					else
						xx <= xx + hor_speed;
		end
	endtask

	task adjust_speed;
		if (speed == 0) begin
			speed <= G;
			speed_dir <= 1;
		end else begin
			if (speed_dir == 0) begin
				speed <= speed - G;
			end else begin
				speed <= speed + G;
			end
		end
	endtask

	task adjust_level;

		begin
			if (score > 24000) level <= 5;
			else if (score > 18000) level <= 4;
			else if (score > 12000) level <= 3;
			else if (score > 6000) level <= 2;
			else if (score > 2000) level <= 1;
		end

	endtask

	reg intersect_flag = 0;
	
	wire intersect_with_blocker_flag;
	assign intersect_with_blocker_flag = 
				((blocker_position[0] < xx + RADIUS - 4) &&
				(blocker_position[0] + BLOCKER_WIDTH > xx + 4) &&
				(yy < blocker_height[0] + 120));
				
	wire intersect_with_bomb_flag;
	assign intersect_with_bomb_flag = 
				(xx + RADIUS - 4 > bomb_x &&
				 xx + 4 < bomb_x + RADIUS + BOMB_RADIUS &&
				 yy + RADIUS - 4 > bomb_y &&
				 yy + 4 < bomb_y + RADIUS + BOMB_RADIUS);

	task initialization;
		begin
			xx 			<= 10'd120;
			yy 			<= HORIZON_HEIGHT;
			speed 		<= 0;
			speed_dir 	<= 0;
			djmp_flag 	<= 1'b1;
			G 			<= 1;
			jump_speed 	<= 12;
			score 		<= 0;
			time_counter<= 0;
			level 		<= 0;
			hor_speed   <= 0;
			hor_speed_dir 	<= 0;
			sugata_counter <= 0;
			test_init_blocker();
		end
	endtask

	task check_jump_over;
		begin
			if ((xx > blocker_position[0] + BLOCKER_WIDTH) &&
				(xx < blocker_position[0] + BLOCKER_WIDTH + speed + (blocker_speed / 2))) begin
				score <= score + (level + 1) * blocker_height[0];
			end
		end
	endtask

	reg [5:0] keyboard_counter = 0;

	always @(posedge clk) begin
		time_counter <= time_counter + 1;
		if (!rstn) begin
			initialization();
		end 
		else begin
			wasReady <= keyReady;
			key_was_ready <= key_ready;
			if (!wasReady&&keyReady) begin
				case (keyCode)
					5'h0 : jump_speed <= jump_speed + 2;
					5'h1 : jump_speed <= jump_speed - 2;
					5'h2 : G <= G + 1;
					5'h3 : G <= G - 1;
					5'h4 : level <= level + 1;
					5'h5 : level <= level - 1;
					5'h12: begin yy <= HORIZON_HEIGHT; speed <= 0; speed_dir <= 0; end
					5'h10:
					case(game_mode)
						RUN_MODE : 	game_mode <= PAUSE_MODE;
						PAUSE_MODE: game_mode <= RUN_MODE;
						FAIL_MODE: begin
							game_mode <= START_MODE;
							initialization();
							bomb_initialize();
						end
						START_MODE: game_mode <= RUN_MODE;
						default:;
					endcase
					5'hc:  xx <= xx - 10'd20;
					5'hd:
						if (yy == HORIZON_HEIGHT) begin
							speed <= jump_speed;
							speed_dir <= 0;
						end else if (|djmp_flag) begin
							djmp_flag <= djmp_flag - 1;
							speed <= jump_speed;
							speed_dir <= 0;
						end
					5'he:  xx <= xx + 10'd20;
					5'hf:  test_init_blocker();
					5'h9:  bg_speed <= bg_speed + 1;
					5'h11: bg_speed <= bg_speed - 1;
					default: ;
				endcase
			end
			
			else if (!key_was_ready && key_ready) begin
				if_keyboard_ready <= 1;
			end
			
			else if (key_was_ready && !key_ready) begin
				case(key_code)
					8'h44:
						hor_speed <= 0;
					8'h41:
						hor_speed <= 0;
					default:;
				endcase
			end

			else if (if_keyboard_ready == 1)begin
				keyboard_counter <= keyboard_counter + 1;
				if (&keyboard_counter) begin
					if_keyboard_ready <= 0;
						case (key_code)
							8'h20:      // space
							case(game_mode)
								RUN_MODE : 	game_mode <= PAUSE_MODE;
								PAUSE_MODE: game_mode <= RUN_MODE;
								FAIL_MODE: begin
									game_mode <= START_MODE;
									initialization();
									bomb_initialize();
								end
								START_MODE: game_mode <= RUN_MODE;
								default:;
							endcase
							8'h57:      // W(jump)
								if (yy == HORIZON_HEIGHT) begin
									speed <= jump_speed;
									speed_dir <= 0;
								end else if (|djmp_flag) begin
									djmp_flag <= djmp_flag - 1;
									speed <= jump_speed;
									speed_dir <= 0;
								end
							8'h44: 	// D
								begin
									hor_speed_dir <= 1;
									hor_speed <= HORIZON_SPEED;
								end
							8'h41: // A
								begin
									hor_speed_dir <= 0;
									hor_speed <= HORIZON_SPEED;
								end
							default: ;
						endcase
				end
			end
		end
		case(game_mode)
			RUN_MODE: begin
					move_counter <= move_counter + 1;
					if (&move_counter) begin
						adjust_level();
						move_background();
						jump_counter <= jump_counter + 1;
						score <= score + (1 + level);
						if (&jump_counter) begin
							sugata_flag <= sugata_flag + 1;
							if (|sugata_flag) begin
								sugata_counter <= sugata_counter + 1;
							end
							move_blocker();
							move_bomb();
							adjust_bomb_speed();
							check_jump_over();
							begin
								if (intersect_with_blocker_flag || intersect_with_bomb_flag) begin
									game_mode <= FAIL_MODE;
								end else begin
									if (((speed_dir == 1) &&
										((speed > jump_speed * 2) 	||
										(speed + HORIZON_HEIGHT > yy)  		||
										(speed + HORIZON_HEIGHT == yy)))) begin
										reset_to_horizon();
									end else begin
										if (speed != 0 || hor_speed != 0) begin
											move_object();
										end
										if (yy != HORIZON_HEIGHT) begin
											adjust_speed();
										end else if (speed != jump_speed) begin
											reset_to_horizon();
										end
									end
								end
							end
						end
					end
				end
			PAUSE_MODE:;
			FAIL_MODE:;
			START_MODE: begin
					move_counter <= move_counter + 1;
					if (&move_counter) begin
						move_background();
					end
				end
			default:;
		endcase
	end

	wire [23:0] temp;
	wire [23:0] temp2;
	wire [23:0] temp3;
	wire [23:0] temp4;
	wire [23:0] temp5;
	wire [23:0] temp6;
	wire [23:0] temp7;
	wire [23:0] temp8;
	wire [23:0] temp9;
	wire [23:0] tempa;

	wire [10:0] calculated_x;
	assign calculated_x = (col_addr + x_offset) % 640;

	background2 your_instance_name (
	  .clka(clkdiv[1]), // input clka
	  .addra({row_addr * 640 + calculated_x}), // input [18 : 0] addra
	  .douta(temp) // output [23 : 0] douta
	);

	wire [10:0] inv_y;
	assign inv_y = row_addr - 360;

	horizon horizon1 (
	  .clka(clkdiv[1]), // input clka
	  .addra({inv_y * 20 + (640 - blocker_position[0] + col_addr) % 20}), // input [12 : 0] addra
	  .douta(temp4) // output [23 : 0] douta
	);

	wire [10:0] blocker_delta_y;
	assign blocker_delta_y = row_addr - (360 - blocker_height[0]);

	blockerip blocker_instance (
		.clka(clkdiv[1]),
		.addra({blocker_delta_y * BLOCKER_WIDTH + (col_addr - blocker_position[0])}),
		.douta(temp5)
	);
	
	titleip title_instance (
	  .clka(clkdiv[1]), // input clka
	  .addra({(row_addr - 100) * 316 + (col_addr - 162)}), // input [14 : 0] addra
	  .douta(temp8) // output [23 : 0] douta
	);
	
	gameoverip gameover_instance (
	  .clka(clkdiv[1]), // input clka
	  .addra({(row_addr - 124) * 336 + (col_addr - 152)}), // input [14 : 0] addra
	  .douta(temp9) // output [23 : 0] douta
	);

	wire [11:0] pic_data;
	wire [11:0] pic_data2;
	wire [11:0] player_data;
	wire [11:0] horizon_data;
	wire [11:0] blocker_data;
	wire [11:0] player_left_data;
	wire [11:0] player_right_data;
	wire [11:0]	title_data;
	wire [11:0] gameover_data;
	wire [11:0] bomb_data;

	assign pic_data =  			{temp [7:4], temp [15:12], temp [23:20]};
	assign pic_data2 = 			{temp2[7:4], temp2[15:12], temp2[23:20]};
	assign player_data = 		{temp3[7:4], temp3[15:12], temp3[23:20]};
	assign horizon_data = 		{temp4[7:4], temp4[15:12], temp4[23:20]};
	assign blocker_data = 		{temp5[7:4], temp5[15:12], temp5[23:20]};
	assign player_left_data = 	{temp6[7:4], temp6[15:12], temp6[23:20]};
	assign player_right_data = 	{temp7[7:4], temp7[15:12], temp7[23:20]};
	assign title_data = 		{temp8[7:4], temp8[15:12], temp8[23:20]};
	assign gameover_data = 		{temp9[7:4], temp9[15:12], temp9[23:20]};
	assign bomb_data = {tempa[7:4], tempa[15:12], tempa[23:20]};

	wire [9:0] delta_x;
	wire [8:0] delta_y;

	assign delta_x = col_addr - xx;
	assign delta_y = row_addr - (480 - yy - RADIUS);

	player player1 (
	  .clka(clkdiv[1]), // input clka
	  .addra({delta_y * 40 + delta_x}), // input [10 : 0] addra
	  .douta(temp3) // output [23 : 0] douta
	);
	
	bombip bomb_instance (
	  .clka(clkdiv[1]), // input clka
	  .addra({(row_addr - (480 - bomb_y - BOMB_RADIUS)) * BOMB_RADIUS + (col_addr - xx)}), // input [10 : 0] addra
	  .douta(tempa) // output [23 : 0] douta
	);

	player_left left_player_instance (
	  .clka(clkdiv[1]), // input clka
	  .addra({delta_y * 40 + delta_x}), // input [10 : 0] addra
	  .douta(temp6) // output [23 : 0] douta
	);

	player_right right_player_instance (
	  .clka(clkdiv[1]), // input clka
	  .addra({delta_y * 40 + delta_x}), // input [10 : 0] addra
	  .douta(temp7) // output [23 : 0] douta
	);

	reg blocker_flag;

	wire [11:0] player_true_data;
	assign player_true_data =
		(sugata_counter == 0 || sugata_counter == 2'b10) ?
			player_data :
			((sugata_counter == 2'b01) ?
				player_left_data :
				player_right_data );
	
	wire [11:0] vga_true_data;
	
	assign vga_true_data = 
		(row_addr >= 360) 
		? horizon_data 
		: (((game_mode == START_MODE) && 
		   (col_addr > 162) && 
		   (col_addr < 478) && 
		   (row_addr > 100) && 
		   (row_addr < 200) && 
		   (title_data != 12'b1111_0000_0000)) 
			? title_data 
			: (((game_mode == FAIL_MODE) &&
				(col_addr > 152) &&
				(col_addr < 488) &&
				(row_addr > 124) &&
				(row_addr < 200) &&
				(gameover_data != 12'b1111_0000_0000)) 
				? gameover_data
				: ((col_addr > bomb_x) &&
					(col_addr < bomb_x + BOMB_RADIUS) &&
					(row_addr < 480 - bomb_y + BOMB_RADIUS) &&
					(row_addr > 480 - bomb_y) &&
					(game_mode != START_MODE) &&
					(bomb_data != 12'b1111_0000_0000)
					? bomb_data
					: (((((col_addr < blocker_position[0] + BLOCKER_WIDTH + 1) &&
						(col_addr > blocker_position[0]) &&
						(row_addr < 360) &&
						(row_addr > 360 - blocker_height[0] - 1)) && blocker_data != 12'b1111_1111_1111)
						? blocker_data
						: (((col_addr > xx) 			&&
							(col_addr < xx + RADIUS) 	&&
							(row_addr < (480 - yy)) 	&&
							(row_addr > (440 - yy)))
							? (((yy == HORIZON_HEIGHT) 
								? ((player_true_data == 12'b1111_1111_1111)
									? pic_data
									: player_true_data)
								: ((player_data == 12'b1111_1111_1111)
									? pic_data
									: player_data)))
							: pic_data))))));
			
	
	always @(posedge clkdiv[1]) begin
		vga_data <= vga_true_data;
	end

	wire [3:0] score_0;
	wire [3:0] score_10;
	wire [3:0] score_100;
	wire [3:0] score_1000;
	wire [3:0] score_10000;
	wire [3:0] score_100000;
	wire [3:0] score_1000000;
	wire [3:0] score_10000000;

	assign score_0 = score % 10;
	assign score_10 = (score % 100) / 10;
	assign score_100 = (score % 1000) / 100;
	assign score_1000 = (score % 10000) / 1000;
	assign score_10000 = (score % 100000) / 10000;
	assign score_100000 = (score % 1000000) / 100000;
	assign score_1000000 = (score % 10000000) / 1000000;
	assign score_10000000 = (score % 100000000) / 10000000;

	assign segTestData = {
		level,
		//score_1000000,
		key_code,
		//score_100000,
		score_10000,
		score_1000,
		score_100,
		score_10,
		score_0
	};
	wire [15:0] ledData;
	assign ledData = {key_ready, 12'b0, game_mode, intersect_flag};
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));
endmodule
