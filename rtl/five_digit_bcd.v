module five_digit_bcd (in, hex0, hex1, hex2, hex3, hex4);
    input signed[15:0] in;
    output [6:0] hex0;
    output [6:0] hex1;
	 output [6:0] hex2;
    output [6:0] hex3;
	 output [6:0] hex4;
	 
	 wire [15:0] s = {16{in[15]}}; 	// all 1s if in is negative, else all 0s
	 wire [15:0] mag = (in ^ s) - s; 	// magnitude = (in XOR s) - s
	 
	 // quotients
	 wire [15:0]q0, q1, q2, q3, q4;
	 
	 // remainders
	 wire [3:0]d0, d1, d2, d3, d4;

	 proc_divide (4'd10, mag, q0, d0); 	// ones
	 proc_divide (4'd10, q0, q1, d1);	// tens
	 proc_divide (4'd10, q1, q2, d2);	// hundreds
	 proc_divide (4'd10, q2, q3, d3);	// thousands
	 
	 assign d4 = q3[3:0];
	 
	 bcd digit1(.data(d0), .X(hex0));
	 bcd digit2(.data(d1), .X(hex1));
	 bcd digit3(.data(d2), .X(hex2));
	 bcd digit4(.data(d3), .X(hex3));
	 bcd digit5(.data(d4), .X(hex4));

endmodule