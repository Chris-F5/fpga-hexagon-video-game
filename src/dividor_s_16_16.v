module div_stage (
    input             clk,
    input      [48:0] in_remainder,
    input      [16:0] in_divisor,
    input      [16:0] in_quotient,
    output reg [16:0] out_divisor,
    output reg [48:0] out_remainder,
    output reg [16:0] out_quotient
);
  // Unsigned subtraction: check if in_remainder >= (in_divisor << 32)
  wire [49:0] sub_result = {1'b0, in_remainder} - {1'b0, 15'b0, in_divisor, 16'b0};

  always @(posedge clk) begin
    if (sub_result[49] == 0) begin
      out_remainder <= sub_result[48:0] << 1;
      out_quotient  <= {in_quotient[15:0], 1'b1};
    end else begin
      out_remainder <= in_remainder << 1;
      out_quotient  <= {in_quotient[15:0], 1'b0};
    end
    out_divisor <= in_divisor;
  end
endmodule

module dividor_s_16_16 (
    input clk,
    input signed [31:0] dividend,
    input signed [16:0] divisor,
    output reg signed [16:0] quotient  // will appear exactly 18 cycles later.
);
  // Determine output sign
  wire sign_out = (dividend[31] ^ divisor[16]);

  // Sign pipeline to match the 17 stages of division
  reg sign_pipe[16:0];
  always @(posedge clk) begin
    sign_pipe[0] <= sign_out;
    for (integer i = 1; i <= 16; i = i + 1) begin
      sign_pipe[i] <= sign_pipe[i-1];
    end
  end

  // Inter-stage registers (needs to be wide enough for 32-bit dividend + 16 zero bits padding)
  wire [48:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17;
  wire [16:0] q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17;
  wire [16:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17;


  // Take absolute values for division
  wire [31:0] abs_dividend = dividend[31] ? -dividend : dividend;
  wire [16:0] abs_divisor = divisor[16] ? -divisor : divisor;

  // Initialize pipeline
  assign r0 = {17'b0, abs_dividend};
  assign d0 = abs_divisor;
  assign q0 = 17'b0;

  // 17 stages for 17-bit output
  div_stage s1 (clk, r0, d0, q0, d1, r1, q1);
  div_stage s2 (clk, r1, d1, q1, d2, r2, q2);
  div_stage s3 (clk, r2, d2, q2, d3, r3, q3);
  div_stage s4 (clk, r3, d3, q3, d4, r4, q4);
  div_stage s5 (clk, r4, d4, q4, d5, r5, q5);
  div_stage s6 (clk, r5, d5, q5, d6, r6, q6);
  div_stage s7 (clk, r6, d6, q6, d7, r7, q7);
  div_stage s8 (clk, r7, d7, q7, d8, r8, q8);
  div_stage s9 (clk, r8, d8, q8, d9, r9, q9);
  div_stage s10 (clk, r9, d9, q9, d10, r10, q10);
  div_stage s11 (clk, r10, d10, q10, d11, r11, q11);
  div_stage s12 (clk, r11, d11, q11, d12, r12, q12);
  div_stage s13 (clk, r12, d12, q12, d13, r13, q13);
  div_stage s14 (clk, r13, d13, q13, d14, r14, q14);
  div_stage s15 (clk, r14, d14, q14, d15, r15, q15);
  div_stage s16 (clk, r15, d15, q15, d16, r16, q16);
  div_stage s17 (clk, r16, d16, q16, d17, r17, q17);

  // Apply sign at the end (adds 1 cycle, making total 18 cycles latency)
  always @(posedge clk) begin
    if (sign_pipe[16]) quotient <= -q17;
    else quotient <= q17;
  end

endmodule
