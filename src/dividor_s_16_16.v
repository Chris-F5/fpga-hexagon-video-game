module div_stage (
    input             clk,
    input      [60:0] in_remainder,
    input      [30:0] in_divisor,
    input      [30:0] in_quotient,
    output reg [30:0] out_divisor,
    output reg [60:0] out_remainder,
    output reg [30:0] out_quotient
);
  // Unsigned subtraction: check if in_remainder >= (in_divisor << 30)
  wire [61:0] sub_result = {1'b0, in_remainder} - {1'b0, in_divisor, 30'b0};

  always @(posedge clk) begin
    if (sub_result[61] == 0) begin
      out_remainder <= sub_result[60:0] << 1;
      out_quotient  <= {in_quotient[29:0], 1'b1};
    end else begin
      out_remainder <= in_remainder << 1;
      out_quotient  <= {in_quotient[29:0], 1'b0};
    end
    out_divisor <= in_divisor;
  end
endmodule

module dividor_s_16_16 (
    input clk,
    input signed [30:0] dividend,
    input signed [30:0] divisor,
    output reg signed [30:0] quotient  // will appear exactly 32 cycles later.
);
  // Determine output sign
  wire sign_out = (dividend[30] ^ divisor[30]);

  // Sign pipeline to match the 31 stages of division
  reg sign_pipe[30:0];
  always @(posedge clk) begin
    sign_pipe[0]  <= sign_out;
    //for (integer i = 1; i <= 30; i = i + 1) begin
    //  sign_pipe[i] <= sign_pipe[i-1];
    //end
    sign_pipe[1]  <= sign_pipe[1-1];
    sign_pipe[2]  <= sign_pipe[2-1];
    sign_pipe[3]  <= sign_pipe[3-1];
    sign_pipe[4]  <= sign_pipe[4-1];
    sign_pipe[5]  <= sign_pipe[5-1];
    sign_pipe[6]  <= sign_pipe[6-1];
    sign_pipe[7]  <= sign_pipe[7-1];
    sign_pipe[8]  <= sign_pipe[8-1];
    sign_pipe[9]  <= sign_pipe[9-1];
    sign_pipe[10] <= sign_pipe[10-1];
    sign_pipe[11] <= sign_pipe[11-1];
    sign_pipe[12] <= sign_pipe[12-1];
    sign_pipe[13] <= sign_pipe[13-1];
    sign_pipe[14] <= sign_pipe[14-1];
    sign_pipe[15] <= sign_pipe[15-1];
    sign_pipe[16] <= sign_pipe[16-1];
    sign_pipe[17] <= sign_pipe[17-1];
    sign_pipe[18] <= sign_pipe[18-1];
    sign_pipe[19] <= sign_pipe[19-1];
    sign_pipe[20] <= sign_pipe[20-1];
    sign_pipe[21] <= sign_pipe[21-1];
    sign_pipe[22] <= sign_pipe[22-1];
    sign_pipe[23] <= sign_pipe[23-1];
    sign_pipe[24] <= sign_pipe[24-1];
    sign_pipe[25] <= sign_pipe[25-1];
    sign_pipe[26] <= sign_pipe[26-1];
    sign_pipe[27] <= sign_pipe[27-1];
    sign_pipe[28] <= sign_pipe[28-1];
    sign_pipe[29] <= sign_pipe[29-1];
    sign_pipe[30] <= sign_pipe[30-1];
  end

  // Inter-stage registers
  wire [60:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31;
  wire [30:0] q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19, q20, q21, q22, q23, q24, q25, q26, q27, q28, q29, q30, q31;
  wire [30:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31;

  // Take absolute values for division
  wire [30:0] abs_dividend = dividend[30] ? -dividend : dividend;
  wire [30:0] abs_divisor = divisor[30] ? -divisor : divisor;

  // Initialize pipeline
  assign r0 = {30'b0, abs_dividend};
  assign d0 = abs_divisor;
  assign q0 = 31'b0;

  // 31 stages for 31-bit output
  div_stage s1 (
      clk,
      r0,
      d0,
      q0,
      d1,
      r1,
      q1
  );
  div_stage s2 (
      clk,
      r1,
      d1,
      q1,
      d2,
      r2,
      q2
  );
  div_stage s3 (
      clk,
      r2,
      d2,
      q2,
      d3,
      r3,
      q3
  );
  div_stage s4 (
      clk,
      r3,
      d3,
      q3,
      d4,
      r4,
      q4
  );
  div_stage s5 (
      clk,
      r4,
      d4,
      q4,
      d5,
      r5,
      q5
  );
  div_stage s6 (
      clk,
      r5,
      d5,
      q5,
      d6,
      r6,
      q6
  );
  div_stage s7 (
      clk,
      r6,
      d6,
      q6,
      d7,
      r7,
      q7
  );
  div_stage s8 (
      clk,
      r7,
      d7,
      q7,
      d8,
      r8,
      q8
  );
  div_stage s9 (
      clk,
      r8,
      d8,
      q8,
      d9,
      r9,
      q9
  );
  div_stage s10 (
      clk,
      r9,
      d9,
      q9,
      d10,
      r10,
      q10
  );
  div_stage s11 (
      clk,
      r10,
      d10,
      q10,
      d11,
      r11,
      q11
  );
  div_stage s12 (
      clk,
      r11,
      d11,
      q11,
      d12,
      r12,
      q12
  );
  div_stage s13 (
      clk,
      r12,
      d12,
      q12,
      d13,
      r13,
      q13
  );
  div_stage s14 (
      clk,
      r13,
      d13,
      q13,
      d14,
      r14,
      q14
  );
  div_stage s15 (
      clk,
      r14,
      d14,
      q14,
      d15,
      r15,
      q15
  );
  div_stage s16 (
      clk,
      r15,
      d15,
      q15,
      d16,
      r16,
      q16
  );
  div_stage s17 (
      clk,
      r16,
      d16,
      q16,
      d17,
      r17,
      q17
  );
  div_stage s18 (
      clk,
      r17,
      d17,
      q17,
      d18,
      r18,
      q18
  );
  div_stage s19 (
      clk,
      r18,
      d18,
      q18,
      d19,
      r19,
      q19
  );
  div_stage s20 (
      clk,
      r19,
      d19,
      q19,
      d20,
      r20,
      q20
  );
  div_stage s21 (
      clk,
      r20,
      d20,
      q20,
      d21,
      r21,
      q21
  );
  div_stage s22 (
      clk,
      r21,
      d21,
      q21,
      d22,
      r22,
      q22
  );
  div_stage s23 (
      clk,
      r22,
      d22,
      q22,
      d23,
      r23,
      q23
  );
  div_stage s24 (
      clk,
      r23,
      d23,
      q23,
      d24,
      r24,
      q24
  );
  div_stage s25 (
      clk,
      r24,
      d24,
      q24,
      d25,
      r25,
      q25
  );
  div_stage s26 (
      clk,
      r25,
      d25,
      q25,
      d26,
      r26,
      q26
  );
  div_stage s27 (
      clk,
      r26,
      d26,
      q26,
      d27,
      r27,
      q27
  );
  div_stage s28 (
      clk,
      r27,
      d27,
      q27,
      d28,
      r28,
      q28
  );
  div_stage s29 (
      clk,
      r28,
      d28,
      q28,
      d29,
      r29,
      q29
  );
  div_stage s30 (
      clk,
      r29,
      d29,
      q29,
      d30,
      r30,
      q30
  );
  div_stage s31 (
      clk,
      r30,
      d30,
      q30,
      d31,
      r31,
      q31
  );

  // Apply sign at the end (adds 1 cycle, making total 32 cycles latency)
  always @(posedge clk) begin
    if (sign_pipe[30]) quotient <= -q31;
    else quotient <= q31;
  end

endmodule
