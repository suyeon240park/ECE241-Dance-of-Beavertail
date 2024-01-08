// square falling down
// when the user presses KEY[1], square disappears, score++
// when the score gets 30, the game end and display won.mif

module fallingSquare(	
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
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour, colour_won;
	wire [7:0] x;
	wire [6:0] y;
	
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	wire go, erase, plotEn, update, reset, won;
	
	wire [5:0] plotCounter;
	wire [7:0] xCounter;
	wire [6:0] yCounter;
	wire [25:0] freq;
    reg [7:0] score;

	// Create an Instance of a VGA controller 
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(go),
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
			
	controlPath c(CLOCK_50, resetn, plotCounter, 
					  xCounter, yCounter, KEY[1],
					  go, erase, update, plotEn, reset, won,
                      score);
	
	dataPath d(CLOCK_50, resetn, plotEn, erase, update, reset, won,
               go, x, y, colour, plotCounter, xCounter, yCounter, freq);

    won_bg wb (y*160 + x, CLOCK_50, colour_won);
endmodule

module controlPath(input clk, resetn,
    input [5:0] plotCounter,
    input [7:0] xCounter,
    input [6:0] yCounter,
    input disappear,
    output reg go, erase, update, plotEn, reset, won,
    output reg [7:0] score);

    reg [2:0] currentSt, nextSt;

    localparam RESET = 3'b0,
        DRAW = 3'b001,
        WAIT = 3'b010,
        UPDATE = 3'b100,
        CLEAR = 3'b101,
        END = 3'b110;

    always @(*)
    begin
        case(currentSt)
            RESET: nextSt = DRAW;
            DRAW: begin
                if (plotCounter <= 6'd15) nextSt = DRAW;
                else nextSt = WAIT;
            end
            WAIT: begin
                if (yCounter == 7'd120) nextSt = CLEAR; // Disappear at bottom without KEY[1]
                else if (disappear) begin
                    score <= score + 1; // Increment score when KEY[1] is pressed
                    if (score >= 8'd30) nextSt = END; // Go to END state if score reaches 30
                    else nextSt = RESET; // Reappear at the top if disappear flag is set
                end
                else nextSt = UPDATE;
            end
            UPDATE: nextSt = DRAW;
            CLEAR: begin
                nextSt = RESET; // Reappear at the top after disappearing at the bottom
            end
            END: begin
                nextSt = END;
            end
            default: nextSt = RESET;
        endcase
    end

    always @(*)
    begin
        go = 1'b0;
        update = 1'b0;
        reset = 1'b0;
        erase = 1'b0;
        plotEn = 1'b0;
        won = 1'b0;
        
        case(currentSt)
            RESET: reset = 1'b1;
            DRAW: begin
                go = 1'b1;
                erase = 1'b0;
                plotEn = 1'b1;
            end
            UPDATE: update = 1'b1;
            CLEAR: begin
                erase = 1'b1; // Set erase to clear the square
                go = 1'b1;
            end
            END: begin
                won = 1'b1;
                go = 1'b1;
            end
        endcase
    end

    always @(posedge clk)
    begin
        if (!resetn) currentSt <= CLEAR;
        else currentSt <= nextSt;
    end 
endmodule



module dataPath(input clk, resetn, plotEn, erase, update, reset, won,
    output go,
    output reg [7:0] X,
    output reg [6:0] Y,
    output reg [2:0] CLR,
    output reg [5:0] plotCounter,
    output reg [7:0] xCounter,
    output reg [6:0] yCounter,
    output reg [25:0] freq);

    reg [15:0] address;

    always @(posedge clk)
    begin
        if (reset || !resetn) begin
            go <= 1'd0;
            X <= 8'd78;
            Y <= 7'b0;
            plotCounter <= 6'b0;
            xCounter <= 8'b0;
            yCounter <= 7'b0;
            CLR <= 3'b100;
            freq <= 25'd0;
        end
        else if (won) begin
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
                go <= 1'b1;
                CLR <= colour_won;
            end
            else begin
                go <= 1'b0;
                address <= 0;
                X <= 0;
                Y <= 0;
            end
        end
        else begin
            if (freq == 26'd12499999) freq <= 26'd0;
            else freq <= freq + 1;
            
            if (plotEn) begin
                CLR <= 3'b100;
                if (plotCounter == 6'b10000) plotCounter <= 6'b0;
                else plotCounter <= plotCounter + 1;
                X <= 8'd78;
                Y <= yCounter + plotCounter[3:0];
            end
            if (update) begin
                yCounter <= Y;
            end
            if (erase) begin
                X <= 8'd78;
                Y <= 7'b0;
            end
        end
    end
endmodule
