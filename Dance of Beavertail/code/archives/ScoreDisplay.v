module hex_decoder(
    input [3:0] hex_digit,
    output reg [6:0] display;
);

// Hexadecimal to 7-segment decoder for digits 0 to 9
always @(*)
    case(hex_digit)
        4'b0000: seven_segment = 7'b1000000; // 0
        4'b0001: seven_segment = 7'b1111001; // 1
        4'b0010: seven_segment = 7'b0100100; // 2
        4'b0011: seven_segment = 7'b0110000; // 3
        4'b0100: seven_segment = 7'b0011001; // 4
        4'b0101: seven_segment = 7'b0010010; // 5
        4'b0110: seven_segment = 7'b0000010; // 6
        4'b0111: seven_segment = 7'b1111000; // 7
        4'b1000: seven_segment = 7'b0000000; // 8
        4'b1001: seven_segment = 7'b0010000; // 9
        default: seven_segment = 7'b1111111; // Invalid
    endcase

endmodule


module ScoreDisplay (
    input wire clk,
    input wire resetn,
    input wire [4:0] score,
    output reg [7:0] LEDR
);

reg [2:0] display_count;  // Counter to track the number of characters to display

always @(posedge clk) begin
    if (!resetn) begin
        LEDR <= 8'b11111111; // Initially turn off all LEDs
    end else begin
        case(score % 7)
            0: LEDR <= 8'b11111111; // Display nothing for score 0 or multiples of 7
            1: LEDR <= 8'b11111110; // Display 'B' for score 1
            2: LEDR <= 8'b11111100; // Display 'BE' for score 2
            3: LEDR <= 8'b11111000; // Display 'BEA' for score 3
            4: LEDR <= 8'b11110000; // Display 'BEAV' for score 4
            5: LEDR <= 8'b11100000; // Display 'BEAVE' for score 5
            6: LEDR <= 8'b11000000; // Display 'BEAVER' for score 6
            default: LEDR <= 8'b11111111; // Default to turn off LEDs
        endcase
    end
end
endmodule


module ScoreDecoder(
    input wire clk,
    input wire resetn,
    input wire [4:0] score,
    output reg [6:0] display
);

reg [2:0] index;

always @(posedge clk) begin
    if (!resetn) begin
        LEDR <= 8'b11111111;
    end
    else begin
	    if (score != 0 && score % 7 == 0) index = 1;
	    else index = score % 7;
	    case(index)
	        0: display = 7'b0000000; // 0, no LEDs lit
            1: display = 7'b0001000; // B
            2: display = 7'b0011100; // BE
            3: display = 7'b0111110; // BEA
            4: display = 7'b1111110; // BEAV
            5: display = 7'b1111111; // BEAVE
            6: display = 7'b1110111; // BEAVER
            default: led_output = 7'b0000000; // no LED
        endcase
    end
end

endmodule
