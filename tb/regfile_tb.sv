// Unit testbench for rtl/core/regfile.sv
//
// Checks:
//   1. x0 always reads 0, even after a write to it
//   2. every register x1..x31 holds its own value (no aliasing)
//   3. we=0 never changes a register
//   4. both read ports can read the same and different registers
//   5. 5000 random cycles against a reference model
//
// Reads are combinational; writes happen on the rising clock edge.

module regfile_tb;

  logic        clk;
  logic [4:0]  rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1_data, rs2_data, rd_data;
  logic        we;

  regfile dut (
    .clk      (clk),
    .rs1_addr (rs1_addr),
    .rs1_data (rs1_data),
    .rs2_addr (rs2_addr),
    .rs2_data (rs2_data),
    .we       (we),
    .rd_addr  (rd_addr),
    .rd_data  (rd_data)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  logic [31:0] model [32];   // reference: what each register should hold
  int          errors = 0;

  // Write one register on the next rising edge.
  task automatic write_reg(input logic [4:0] addr, input logic [31:0] data);
    @(negedge clk);
    we      = 1;
    rd_addr = addr;
    rd_data = data;
    @(posedge clk);
    #1 we   = 0;
    if (addr != 0) model[addr] = data;
  endtask

  // Read through both ports and compare against the model.
  task automatic check_read(input logic [4:0] a1, input logic [4:0] a2, input string what);
    rs1_addr = a1;
    rs2_addr = a2;
    #1;
    if (rs1_data !== model[a1]) begin
      $display("FAIL [%s] rs1: x%0d = %h, expected %h", what, a1, rs1_data, model[a1]);
      errors++;
    end
    if (rs2_data !== model[a2]) begin
      $display("FAIL [%s] rs2: x%0d = %h, expected %h", what, a2, rs2_data, model[a2]);
      errors++;
    end
  endtask

  initial begin
    we = 0; rd_addr = 0; rd_data = 0; rs1_addr = 0; rs2_addr = 0;
    foreach (model[i]) model[i] = 0;

    // Registers have no reset, so give every one a known value first.
    for (int r = 1; r < 32; r++) write_reg(r[4:0], 32'h0);

    // 1. x0 is hardwired to zero.
    write_reg(5'd0, 32'hdeadbeef);
    check_read(5'd0, 5'd0, "x0 ignores writes");

    // 2. Each register stores its own value.
    for (int r = 1; r < 32; r++) write_reg(r[4:0], 32'h1000_0000 | r);
    for (int r = 0; r < 32; r++) check_read(r[4:0], 5'(31 - r), "unique values");

    // 3. we=0 must not write.
    @(negedge clk);
    we = 0; rd_addr = 5'd7; rd_data = 32'hffff_ffff;
    @(posedge clk); #1;
    check_read(5'd7, 5'd7, "we=0 does not write");

    // 4. Both ports reading the same register.
    write_reg(5'd12, 32'h1234_5678);
    check_read(5'd12, 5'd12, "same register on both ports");

    // 5. Random writes and reads against the model.
    for (int i = 0; i < 5000; i++) begin
      @(negedge clk);
      // Check reads of the current state before the next edge.
      check_read(5'($urandom), 5'($urandom), "random");
      we      = 1'($urandom);
      rd_addr = 5'($urandom);
      rd_data = $urandom;
      @(posedge clk);
      if (we && rd_addr != 0) model[rd_addr] = rd_data;
    end
    // Change inputs only on the falling edge, never at the rising edge
    // the DUT samples on, to avoid a race with the last write.
    @(negedge clk);
    we = 0;
    for (int r = 0; r < 32; r++) check_read(r[4:0], r[4:0], "final state");

    if (errors == 0) $display("PASS  regfile");
    else             $fatal(1, "FAIL  regfile (%0d errors)", errors);
    $finish;
  end

endmodule
