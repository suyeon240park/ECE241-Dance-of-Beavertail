module fallingLetters(    
    input           CLOCK_50,       // On Board 50 MHz
    input   [3:0]   KEY,            // On Board Keys
    input   [9:0]   SW,             // On Board Switches
    output          VGA_CLK,        // VGA Clock
    output          VGA_HS,         // VGA H_SYNC
    output          VGA_VS,         // VGA V_SYNC
    output          VGA_BLANK_N,    // VGA BLANK
    output          VGA_SYNC_N,     // VGA SYNC
    output  [7:0]   VGA_R,          // VGA Red[7:0] Changed from 10 to 8-bit DAC
    output  [7:0]   VGA_G,          // VGA Green[7:0]
    output  [7:0]   VGA_B           // VGA Blue[7:0]
);

    wire resetn = KEY[0];
	 wire start = SW[0];

    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
	 wire [25:0] timeCounter;
    wire gone, create, plot;

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
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";
	 
    control c1 (CLOCK_50, resetn, gone, start, timeCounter, create);
    datapath d1 (CLOCK_50, resetn, create, gone, plot, x, y, timeCounter);
	 
	 beaver1 b1 (y*160 + x, CLOCK_50, colour);
	 
endmodule

module control (
    input clk, resetn, gone, start,
	 input [25:0] timeCounter,
    output reg create
);

    reg [1:0] currentSt, nextSt;

    localparam RESET = 2'b00,
				  WAIT = 2'b01,
              CREATE = 2'b10, // make a state for displaying different images
              GONE   = 2'b11;

    // State Table
    always @(*) begin
        case(currentSt)
            RESET: begin
                if (start) nextSt = CREATE;
                else nextSt = RESET;
            end
            CREATE: begin
						if (gone) nextSt = WAIT;
						else nextSt = CREATE;
				end
				WAIT: begin
					if (timeCounter < 26'd12499999) nextSt = WAIT;
					else nextSt = GONE;
				end
            GONE: nextSt = RESET;
            default: nextSt = RESET;
        endcase
    end 

    // Control signals
    always @(*) begin
        create = 1'b0;
        
        case(currentSt)
            CREATE: create  = 1'b1;
        endcase
    end

    // Control current state
    always @(posedge clk) begin
        if (!resetn) currentSt <= RESET;
        else currentSt <= nextSt;
    end
	
endmodule

module datapath (
    input clk, resetn, create,
	 output reg gone, plot,
    output reg [7:0] X,
    output reg [6:0] Y,
	 output reg [25:0] timeCounter
);
    reg [15:0] address;

    always @(posedge clk) begin
        if (!resetn) begin
            X <= 8'b0;
            Y <= 7'b0;
				address <= 16'b0;
				plot <= 1'b1;
        end
		  else begin
            // Logic to read the image
            if (create) begin
					if (address < 160) begin
						X <= address;
						Y <= 0;
					end
					else begin
						if (address % 160 == 0) begin
							X <= 0;
							Y <= Y + 1;
						end
						else begin
							X <= address % 160;
							Y <= address / 160;
						end
					end
					address <= address + 1;
					
            end
        end
    end
	 
endmodule


