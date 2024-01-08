module fallingLetters(	
		CLOCK_50,						//	On Board 50 MHz
		SW, 								// On Board Switches
		KEY,
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B
	);

	input		    CLOCK_50;			//	50 MHz
	input	 [3:0] KEY;					// Keys
	input  [9:0] SW;					// Switches
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output		 VGA_CLK;   		//	VGA Clock
	output		 VGA_HS;				//	VGA H_SYNC
	output		 VGA_VS;				//	VGA V_SYNC
	output		 VGA_BLANK_N;		//	VGA BLANK
	output		 VGA_SYNC_N;		//	VGA SYNC
	output [7:0] VGA_R;   			//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output [7:0] VGA_G;	 			//	VGA Green[7:0]
	output [7:0] VGA_B;   			//	VGA Blue[7:0]
	
	
	wire resetn, plot;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour, colour1, colour4, colour_default, colour_won;
	wire [7:0] x;
	wire [6:0] y;

	wire create1, create4, createBD;
	wire [5:0] score;

	// Create an Instance of a VGA controller 
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "start_page.mif";
	
	control c1 (CLOCK_50, resetn, ~KEY[1], ~KEY[2], ~KEY[3], score, create1, create4, createBD, ending);
	datapath d1 (CLOCK_50, resetn, create1, create4, createBD, ending, plot, x, y, score);
	
	chooseImage ci (CLOCK_50, create1, create4, createBD, ending, plot, colour1, colour4, colour_default, colour_won, colour);

	ScoreDecoder h3(score / 10, HEX3);
	ScoreDecoder h4(score % 10, HEX4);
	

   	beaver_default bd (y*160 + x, CLOCK_50, colour_default);
   	beaver2 b2 (y*160 + x, CLOCK_50, colour4);
   	beaver3 b3 (y*160 + x, CLOCK_50, colour1);
		won w (y*160 + x, CLOCK_50, colour_won);

endmodule


module chooseImage (input clk, create1, create4, createBD, ending, plot,
					input [2:0] colour1, colour4, colour_default, colour_won,
					output reg [2:0] colour );

	always @(posedge clk) begin
		if (plot) begin 
			if (create1) colour <= colour1;
			else if (create4) colour <= colour4;
			else if (createBD) colour <= colour_default;
			else if (ending) colour <= colour_won;
			else colour <= colour1;
		end
	end
endmodule

module control (input clk, resetn, start, pick1, pick4,
					input [5:0] score,
                output reg create1, create4, createBD, ending);

    reg [2:0] currentSt, nextSt;

    localparam  RESET = 3'b000,
                START = 3'b001,
                CREATEB1 = 3'b010,
                CREATEB4 = 3'b011,
					 CREATEBD = 3'b101,
					 END = 3'b110;

    //State Table
    always @(*)
    begin
        case(currentSt)
            RESET: begin
				//changed this only so far
                if (start) nextSt = START;
                else nextSt = RESET;
            end
            START: begin
                if (!resetn) nextSt = RESET;
                else if (pick1) nextSt = CREATEB1;
                else if (pick4) nextSt = CREATEB4;
                else nextSt = CREATEBD;
            end
            CREATEB1: begin
                if (!resetn) nextSt = RESET;
                else if (pick4) nextSt = CREATEB4;
					 else if (pick1) nextSt = CREATEB1;
					 else if (score > 30) nextSt = END;
                else nextSt = CREATEBD;
            end
            CREATEB4: begin
                if (!resetn) nextSt = RESET;
                else if (pick1) nextSt = CREATEB1;
					 else if (pick4) nextSt = CREATEB4;
					 else if (score > 30) nextSt = END;
                else nextSt = CREATEBD;
				end
				CREATEBD: begin
					if (!resetn) nextSt = RESET;
					else if (pick1) nextSt = CREATEB1;
					else if (pick4) nextSt = CREATEB4;
					else if (score > 30) nextSt = END;
					else nextSt = CREATEBD;
				end
				END: begin
					if (!resetn) nextSt = RESET;
				end
            default: nextSt = RESET;
        endcase
    end 

    //Control signals
    always @(*)
    begin
        create1 = 1'b0;
        create4 = 1'b0;
		  createBD = 1'b0;
		  ending = 1'b0;
        
        case(currentSt)
            CREATEB1: create1  = 1'b1;
            CREATEB4: create4 = 1'b1;
				CREATEBD: createBD = 1'b1;
				END: ending = 1'b1;
        endcase
    end

    // Control current state
    always @(posedge clk)
    begin
        if (!resetn) currentSt <= RESET;
        else currentSt <= nextSt;
    end
endmodule

module datapath (
    input clk, resetn, create1, create4, createBD, ending,
	output reg plot,
    output reg [7:0] X,
    output reg [6:0] Y,
	 output reg [5:0] score
);
    reg [15:0] address;
	 

	always @(posedge clk) begin
		if (!resetn) begin
			X <= 8'b0;
         	Y <= 7'b0;
	      	address <= 16'b0;
			plot <= 1'b0;
			score <= 6'b0;
		end
		else begin
			// Logic to read the image
         	if (create1 || create4 || createBD || ending) begin
				if (create1) score <= score + 1;
				if (create4) score <= score + 2;
				if (address < 19200) begin
					if (address < 160) begin
						X <= address;
                  		Y <= 0;
					end
					else if (address % 160 == 0) begin
						X <= 0;
                 		Y <= Y + 1;
               		end
            		else begin
                  		X <= address % 160;
                  		Y <= address / 160;
               		end
					address <= address + 1;
					plot <= 1'b1;
				end
				else begin
					plot <= 1'b0;
					address <= 0;
					X <= 0;
					Y <= 0;
				end
			end
			else begin
			    plot <= 1'b0;
				 address <= 0;
				 X <= 0;
				 Y <= 0;
			end
		end
	end
endmodule


module ScoreDecoder(
    input wire [5:0] hex_number,
    output reg [6:0] seven_seg
);

always @(*)
    case(hex_number)
        4'b0000: seven_seg = 7'b1000000; // 0
        4'b0001: seven_seg = 7'b1111001; // 1
        4'b0010: seven_seg = 7'b0100100; // 2
        4'b0011: seven_seg = 7'b0110000; // 3
        4'b0100: seven_seg = 7'b0011001; // 4
        4'b0101: seven_seg = 7'b0010010; // 5
        4'b0110: seven_seg = 7'b0000010; // 6
        4'b0111: seven_seg = 7'b1111000; // 7
        4'b1000: seven_seg = 7'b0000000; // 8
        4'b1001: seven_seg = 7'b0010000; // 9
        default: seven_seg = 7'b1111111; // Off or Error
    endcase

endmodule


