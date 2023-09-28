`timescale 1ns / 1ns

module part2(LEDR, SW);
    input [9:0] SW;
    output [9:0] LEDR;
    mux2to1 p1(
	.x(SW[0]),
	.y(SW[1]),
	.s(SW[9]),
	.m(LEDR[0]));
endmodule

module mux2to1 (x, y, s, m);
    input x, y, s;
    output m;
    wire w1, w2, w3;

    v7404 u0 (.pin1(s), .pin2(w1));
    v7408 u1 (.pin1(x), .pin2(w1), .pin3(w2), .pin13(y), .pin12(s), .pin11(w3));
    v7432 u3 (.pin1(w3), .pin2(w2), .pin3(m));
endmodule

module v7404 (pin1, pin3, pin5, pin9, pin11, pin13, pin2, pin4, pin6, pin8,
pin10, pin12);
    input pin1, pin3, pin5, pin13, pin11, pin9;
    output pin2, pin4, pin6, pin12, pin10, pin8;

    assign pin2  = ! pin1;
    assign pin4  = ! pin3;
    assign pin6  = ! pin5;
    assign pin8  = ! pin9;
    assign pin10 = ! pin11;
    assign pin12 = ! pin13;

endmodule  

module v7408 (pin1, pin3, pin5, pin9, pin11, pin13, pin2, pin4, pin6, pin8,
pin10, pin12);
    input pin1, pin2, pin4, pin5, pin9, pin10, pin12, pin13;
    output pin3, pin6, pin8, pin11;

    assign pin3  = (pin1  & pin2);
    assign pin6  = (pin4  & pin5);
    assign pin8  = (pin9  & pin10);
    assign pin11 = (pin12 & pin13);

endmodule  

module v7432 (pin1, pin3, pin5, pin9, pin11, pin13, pin2, pin4, pin6, pin8,
pin10, pin12);
    input pin1, pin2, pin4, pin5, pin9, pin10, pin12, pin13;
    output pin3, pin6, pin8, pin11;

    assign pin3  = (pin1  | pin2);
    assign pin6  = (pin4  | pin5);
    assign pin8  = (pin9  | pin10);
    assign pin11 = (pin12 | pin13);

endmodule
