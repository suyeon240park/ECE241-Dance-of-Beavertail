module fallingLetters(	
		CLOCK_50,						//	On Board 50 MHz
		SW, 								// On Board Switches
		KEY,							   // On Board Keys
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						   //	VGA Blue[9:0]
	);

	input		    CLOCK_50;			//	50 MHz
	input	 [3:0] KEY;					// Keys
	input  [9:0] SW;					// Switches
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
	wire [2:0] colour, colour1, colour4, colour_default;
	wire [7:0] x;
	wire [6:0] y;
	
	wire writeEn;
	assign writeEn = 1;
	wire create1, create4;

	// Create an Instance of a VGA controller 
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
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
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	control c1 (CLOCK_50, resetn, SW[0], SW[1], SW[4], create1, create4);
	datapath d1 (CLOCK_50, resetn, create1, create4, plot, x, y);
	
	chooseImage ci (CLOCK_50, create1, create4, plot, colour1, colour4, colour_default, colour);

   	beaver_default bd (y*160 + x, CLOCK_50, colour_default);
   	beaver4 b4 (y*160 + x, CLOCK_50, colour1);
   	beaver1 b1 (y*160 + x, CLOCK_50, colour4);

endmodule

module chooseImage (input clk, create1, create4, plot,
					input [2:0] colour1, colour4, colour_default,
					output reg [2:0] colour );

	always @(posedge clk) begin
		if (plot) begin 
			if (create1 && !create4) colour <= colour1;
			else if (create4 && !create1) colour <= colour4;
			else colour <= colour_default;
		end
		else colour <= colour_default;
	end
endmodule

module control (input clk, resetn, start, pick1, pick4,
                output reg create1, create4);

    reg [1:0] currentSt, nextSt;

    localparam  RESET = 2'b00,
                START = 2'b01,
                CREATEB1 = 2'b10,
                CREATEB4 = 2'b11;

    //State Table
    always @(*)
    begin
        case(currentSt)
            RESET: begin
                if (start) nextSt = START;
                else nextSt = RESET;
            end
            START: begin
                if (!resetn) nextSt = RESET;
                else if (pick1) nextSt = CREATEB1;
                else if (pick4) nextSt = CREATEB4;
                else nextSt = START;
            end
            CREATEB1: begin
                if (!resetn) nextSt = RESET;
                else if (pick4) nextSt = CREATEB4;
                else nextSt = CREATEB1;
            end
            CREATEB4: begin
                if (!resetn) nextSt = RESET;
                else if (pick1) nextSt = CREATEB1;
                else nextSt = CREATEB4;
				end
            default: nextSt = RESET;
        endcase
    end 

    //Control signals
    always @(*)
    begin
        create1 = 1'b0;
        create4 = 1'b0;
        
        case(currentSt)
            CREATEB1: create1  = 1'b1;
            CREATEB4: create4 = 1'b1;
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
    input clk, resetn, create1, create4,
	output reg plot,
    output reg [7:0] X,
    output reg [6:0] Y
);
    reg [15:0] address;

	always @(posedge clk) begin
		if (!resetn) begin
			X <= 8'b0;
         	Y <= 7'b0;
	      	address <= 16'b0;
			plot <= 1'b0;
		end
		else begin
			// Logic to read the image
         	if (create1 || create4) begin
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
			else plot <= 1'b0;
		end
	end
endmodule
