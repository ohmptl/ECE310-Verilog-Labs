/*
Module Name: Project3_tb_ex

Designer: Sharath Pendyala - spendya@ncsu.edu
// !!!!! PLEASE DO NOT SEND ANY EMAILS WITH QUESTIONS !!!!!
Description: Testbench for Project3

Ver: 1.2

Changes: 
1.0:  Initial design. Autochecker. Doesn't check for reset. Doesn't force edge cases.Includes watchdog timer for no read responses. Forces result to be positive by making sure input_1 >= input_2
      Includes at least 150 cycles of wait time after end of test, potentially much longer if num read tests doesn't match configured tests.
1.1:  Bug fix in looking at result. False positives observed when data has a "96" in it in some form. Fixed.
1.2:  Output Data Stream prints the correct number of bits.
*/


/******************************************************************
 * HOW TO USE THIS TESTBENCH
*******************************************************************


  - "NUM_TEST_VECTORS" can be changed. Max value that can be set is 128.
    - The max value itself could be changed using "MAX_NUM_TESTS".
    - Make sure you increase your simulation time in Vivado (if you are using this testbench on Vivado)
  - "DEBUG_LEVEL" is a useful parameter.
    - Change it to display more debug information. 1 and 2 are useful. 3 was mainly used to debug the testbench.
    - Add more debug information as required either in the tb or in the design.
  - The test vectors themselves are pseudorandom, generated using $urandom_range().
  - The testbench also sends in random length incorrect control signal before the correct packet is sent.
    - Currently, it can send between 0 and 15 incorrect bits.
    - This value is controlled by the parameter "MAX_INCORRECT_CONTROL_WORD_SIZE". 0 to ("MAX_INCORRECT_CONTROL_WORD_SIZE"-1).
    - This can be disabled by commenting out the define "ENABLE_INCORRECT_CONTROL_SIGNAL" (line 52)
  - Task t_run_single_test() sends a single write packet.
  - Task t_run_n_tests() uses the task t_run_single_test() to send multiple packets.
  - Lines 306 to 312 of t_run_single_test() force the result to be positive by making sure input_1 >= input_2.
    - This can be turned OFF or ON using the define "RESULT_NON_NEGATIVE" (line 51) (comment line 51 to have negative results)
  - The define "BREAK_BETWEEN_TESTS" (line 50) adds 2 cycles of no data between consecutive packets.
    - Turn it ON or OFF by either leaving line as such (ON) or by commenting that line (OFF).
  - Do not change parameters related to Header/Data size. I cannot guarantee that the testbench will work when those parameters are changed.
    - I believe it might only break the display statements and not the actual functionality, but why risk it.

*/



`timescale 1ns/1ps

`define DUT_NAME Project3
`define RESULT_NON_NEGATIVE // forces non-negative results by making input_1 >= input_2
`define BREAK_BETWEEN_TESTS // enables 2 clock cycles of gap between each packet.
`define ENABLE_INCORRECT_CONTROL_SIGNAL // send a few random bits of incorrect control signal before sending in the correct packet


module Project3_tb_ex;

  // Clock/delay parameters
  localparam CLK_FREQ_MHZ = 100; // MHz
  localparam CLK_PERIOD = $floor((1000 / CLK_FREQ_MHZ) * 1000) / 1000; // ns, then make sure only 3 bits of precision in fractional part
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2; // ns


  // Test parameters
  localparam MAX_NUM_TESTS = 128; // max value you can configure NUM_TEST_VECTORS
  localparam NUM_TEST_VECTORS = 64; //  number of tests to run
  localparam MAX_NUM_TESTS_BITS = $rtoi($ceil($clog2(MAX_NUM_TESTS)))+1; // an extra bit to be safe.
  localparam RESULT_WDT_MAX_VAL = 100; // Result Watchdog timer. max wait for either 100 cycles or if a next valid din is completely transmitted.
  localparam RESULT_WDT_BITS = $rtoi($ceil($clog2(RESULT_WDT_MAX_VAL)))+1;


  // Header/Data size parameters
  localparam INPUT_CONTROL_DATA_SIZE = 8 + 1 + 16 + 16; // size of control word + op code + inputs
  localparam MAX_INCORRECT_CONTROL_WORD_SIZE = 16; // max number of dummy incorrect control words at the start (multiple of 4)
  localparam OUTPUT_CONTROL_DATA_SIZE = 8 + 20;
  localparam INPUT_SHIFT_REG_SIZE = MAX_INCORRECT_CONTROL_WORD_SIZE + INPUT_CONTROL_DATA_SIZE;


  // Debug parameters
  localparam DEBUG_LEVEL = 2; // 1 general messages, 2 a few useful messages, 3 to debug the testbench


  logic clock = 'b0;
  logic reset = 'b0;
  logic din;
  logic result;

  logic add_sub_select = 'b0;

  logic [INPUT_SHIFT_REG_SIZE-1:0] din_shift_reg = 'b0;
  logic [OUTPUT_CONTROL_DATA_SIZE-1:0] dout_shift_reg = 'b0;
  logic load_din_shift_reg = 'b0;

  logic [MAX_NUM_TESTS_BITS-1:0] current_write_test_num = 'd0;
  logic [MAX_NUM_TESTS_BITS-1:0] current_read_test_num = 'd0;
  logic [RESULT_WDT_BITS-1:0] result_wdt = RESULT_WDT_MAX_VAL;
  logic observe_output = 'b0; // only when 1, observe output
  integer num_tests_pass = 0;
  integer num_tests_fail = 0;

  logic [OUTPUT_CONTROL_DATA_SIZE-1:0] expected_data [0:MAX_NUM_TESTS];

  // Signals for task
  integer num_dummy_control_seq = 0; // up to 15 bits of some incorrect control signal
  logic num_dummy_control_seq_reg = 'b0; // up to 15 bits of some incorrect control signal
  integer shift_reg_size = 0;

  logic [MAX_INCORRECT_CONTROL_WORD_SIZE-1:0] incorrect_control_signal = 'b0;
  logic [INPUT_CONTROL_DATA_SIZE-1:0] correct_control_data = 'b0;
  logic [INPUT_SHIFT_REG_SIZE-1:0] data_out_reg = 'b0;
  logic [13:0] din_1_bin = 'b0;
  logic [13:0] din_2_bin = 'b0;
  logic [14:0] expected_dout_bin = 'b0;
  logic [13:0] temp = 'b0;
  logic [15:0] din_1_bcd = 'b0;
  logic [15:0] din_2_bcd = 'b0;
  logic [19:0] expected_dout_bcd = 'b0;
  logic op = 'b0;


  genvar ii;
  integer jj;

  
  `DUT_NAME dut (
    .clock  (clock),
    .reset  (reset),
    .din    (din),
    .result (result)
  );
  

  // Task to initialize, read any files if needed
  task t_initialize_test;
    begin
      $display("");
      $timeformat(-9, 3, "ns", 9); // -9 = ns. 3 = 3 places after decimal. 12 = min digits
      //$readmemh("./test_vectors.txt", test_vectors);
      //$dumpfile("tb_waveform.vcd");
      //$dumpvars(0, tb_Project3);
    end
  endtask
  

  // Task to set TB registers to a reset state
  task t_reset_tb_regs;
    begin
      clock = 'b0;
      reset = 'b0;

      add_sub_select = 0;

      din_shift_reg = 'b0;
      dout_shift_reg = 'b0;
      load_din_shift_reg = 'b0;

      current_write_test_num = 'b0;
      current_read_test_num = 'b0;
      result_wdt = RESULT_WDT_MAX_VAL;
      observe_output = 'b0;
      num_tests_pass = 0;
      num_tests_fail = 0;

      for (jj = 0; jj < MAX_NUM_TESTS; jj = jj + 1) begin
        expected_data[jj] = 'd0;
      end

      num_dummy_control_seq = 0;
      num_dummy_control_seq_reg = 'b0;
      shift_reg_size = 0;

      incorrect_control_signal = 'b0;
      correct_control_data = 'b0;
      data_out_reg = 'b0;
      din_1_bin = 'b0;
      din_2_bin = 'b0;
      expected_dout_bin = 'b0;
      temp = 'b0;
      din_1_bcd = 'b0;
      din_2_bcd = 'b0;
      expected_dout_bcd = 'b0;
      op = 'b0;

      t_n_cycle_clk_delay(5);
    end
  endtask
  
  // Task for N cycles of delay for clock
  task t_n_cycle_clk_delay;
    input integer num;
    begin
      repeat(num) begin
        @(posedge clock);
      end
    end
  endtask

  // Task to set TB registers to a reset state
  task t_assert_tb_reset;
    begin
      t_n_cycle_clk_delay(2);
      reset = 'b1;
      t_n_cycle_clk_delay(5);
      reset = 'b0;
      t_n_cycle_clk_delay(5);
    end
  endtask

  // Function to convert bin to bcd. Double-Dabble.
  function automatic logic [15:0] f_bin_to_bcd_4_digits(input logic [13:0] bin);
    logic [15:0] bcd = 'b0;

    for (jj = 0; jj < 14; jj = jj + 1) begin
      if (bcd[3:0] >= 5)
        bcd[3:0] = bcd[3:0] + 3;
      if (bcd[7:4] >= 5)
        bcd[7:4] = bcd[7:4] + 3;
      if (bcd[11:8] >= 5)
        bcd[11:8] = bcd[11:8] + 3;
      if (bcd[15:12] >= 5)
        bcd[15:12] = bcd[15:12] + 3;
      bcd = {bcd[14:0], bin[13-jj]};
    end

    return bcd;
  endfunction : f_bin_to_bcd_4_digits

  // Function to convert bin to bcd. Double-Dabble.
  function automatic logic [19:0] f_bin_to_bcd_5_digits(input logic [14:0] bin);
    logic [19:0] bcd = 'b0;

    for (jj = 0; jj < 15; jj = jj + 1) begin
      if (bcd[3:0] >= 5) begin
        bcd[3:0] = bcd[3:0] + 3;
      end

      if (bcd[7:4] >= 5) begin
        bcd[7:4] = bcd[7:4] + 3;
      end

      if (bcd[11:8] >= 5) begin
        bcd[11:8] = bcd[11:8] + 3;
      end

      if (bcd[15:12] >= 5) begin
        bcd[15:12] = bcd[15:12] + 3;
      end

      if (bcd[19:16] >= 5) begin
        bcd[19:16] = bcd[19:16] + 3;
      end

      bcd = {bcd[18:0], bin[14-jj]};
    end

    return bcd;
  endfunction : f_bin_to_bcd_5_digits

  // Function to convert bcd to bin.
  function automatic logic [13:0] f_bcd_to_bin(input logic [15:0] bcd);
    logic [13:0] bin = 'b0;
    logic [3:0] bcd_0 = bcd[3:0];
    logic [3:0] bcd_1 = bcd[7:4];
    logic [3:0] bcd_2 = bcd[11:8];
    logic [3:0] bcd_3 = bcd[15:12];

    bin = (bcd_3 * 'd1000) + (bcd_2 * 'd100) + (bcd_1 * 'd10) + bcd_0;

    return bin;
  endfunction : f_bcd_to_bin

  // Run a single test with din_1 >= din_2
  task t_run_single_test;
    input integer add_sub; // 0 = add, 1 = sub
    begin
      if (DEBUG_LEVEL > 0) begin
        $display("");
        $display("[%0t]: Configuring Write Test %2d.", $realtime, current_write_test_num);
      end

      num_dummy_control_seq = $urandom_range(0,MAX_INCORRECT_CONTROL_WORD_SIZE-1); // up to 15 bits of some incorrect control signal
      `ifndef ENABLE_INCORRECT_CONTROL_SIGNAL
        num_dummy_control_seq = 0; // temporary override
      `endif

      if (num_dummy_control_seq < 0) begin
        num_dummy_control_seq = -num_dummy_control_seq;
      end

      num_dummy_control_seq_reg = num_dummy_control_seq;
      shift_reg_size = num_dummy_control_seq + INPUT_CONTROL_DATA_SIZE;

      incorrect_control_signal = 'b0;
      correct_control_data = 'b0;
      data_out_reg = 'b0;
      din_1_bin = 'b0;
      din_2_bin = 'b0;
      temp = 'b0;
      din_1_bcd = 'b0;
      din_2_bcd = 'b0;
      op = 'b0;

/*********************************************************************/
/*********************************************************************/
/*********************************************************************/
/*
		Specify TWO 4-digit decimal numbers below (currently random)
		Requirement: din_1_bin >= din_2_bin
*/

		din_1_bin = $urandom_range(0,9999); //3627;
		din_2_bin = $urandom_range(0,9999); //1287;
	  
/*********************************************************************/  
/*********************************************************************/
/*********************************************************************/	  

      `ifdef RESULT_NON_NEGATIVE
        if (din_2_bin > din_1_bin) begin
          temp = din_1_bin;
          din_1_bin = din_2_bin;
          din_2_bin = temp;
        end
      `endif

      if (add_sub == 0) begin
        op = 'b0; // add
        expected_dout_bin = din_1_bin + din_2_bin;
      end else begin
        op = 'b1; // sub
        expected_dout_bin = din_1_bin - din_2_bin;
      end

      din_1_bcd = f_bin_to_bcd_4_digits(din_1_bin);
      din_2_bcd = f_bin_to_bcd_4_digits(din_2_bin);
      expected_dout_bcd = f_bin_to_bcd_5_digits(expected_dout_bin);

      correct_control_data = {8'h5A, op, din_1_bcd, din_2_bcd};
      expected_data[current_write_test_num] = {8'h96, expected_dout_bcd};

      if (DEBUG_LEVEL > 1) begin
        $display("[%0t]: Num Dummy Control bits    = %3d", $realtime, num_dummy_control_seq);
        $display("[%0t]: Data-1 BCD                = %b_%b_%b_%b", $realtime, din_1_bcd[15-:4], din_1_bcd[11-:4], din_1_bcd[7-:4], din_1_bcd[3-:4]);
        $display("[%0t]: Data-2 BCD                = %b_%b_%b_%b", $realtime, din_2_bcd[15-:4], din_2_bcd[11-:4], din_2_bcd[7-:4], din_2_bcd[3-:4]);
        $display("[%0t]: Data-1 (Decimal)          = %d", $realtime, din_1_bin[13:0]);
        $display("[%0t]: Data-2 (Decimal)          = %d", $realtime, din_2_bin[13:0]);
        $display("[%0t]: Operation                 = %b (0-add, 1-subtract)", $realtime, op);
        $display("[%0t]: Expected Result BCD       = %b_%b_%b_%b_%b", $realtime, expected_dout_bcd[19-:4], expected_dout_bcd[15-:4], expected_dout_bcd[11-:4], expected_dout_bcd[7-:4], expected_dout_bcd[3-:4]);
        $display("[%0t]: Expected Result (Decimal) = %d", $realtime, expected_dout_bin);
      end

      /*
      // fill in incorrect header
      while (num_dummy_control_seq > 0) begin
        if (num_dummy_control_seq > 3) begin
          incorrect_control_signal[3:0] = 4'hA;
          incorrect_control_signal = incorrect_control_signal << 4;
          num_dummy_control_seq = num_dummy_control_seq - 4;
        end else if (num_dummy_control_seq > 1) begin
          incorrect_control_signal[1:0] = 2'b10;
          incorrect_control_signal = incorrect_control_signal << 2;
          num_dummy_control_seq = num_dummy_control_seq - 2;
        end else begin
          incorrect_control_signal[0] = 1'b1;
          num_dummy_control_seq = num_dummy_control_seq - 1;
        end
      end
      */

      incorrect_control_signal = {(MAX_INCORRECT_CONTROL_WORD_SIZE/4){4'hA}};

      data_out_reg = {incorrect_control_signal, correct_control_data};


      if (DEBUG_LEVEL > 0) begin
        //$display("[%0t]: Data Stream (binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[(INPUT_SHIFT_REG_SIZE-1)-:MAX_INCORRECT_CONTROL_WORD_SIZE], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
        case(num_dummy_control_seq)
          0: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          1: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          2: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:2], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          3: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:3], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          4: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          5: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:5], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          6: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:6], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          7: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:7], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          8: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          9: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:9], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          10: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:10], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          11: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:11], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          12: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:12], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          13: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:13], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          14: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:14], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          15: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:15], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          16: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:16], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
          default: $display("[%0t]: Data Stream (Binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[INPUT_CONTROL_DATA_SIZE+:MAX_INCORRECT_CONTROL_WORD_SIZE], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4]);
        endcase
        //$display("\t\t\t\tNote: MSB %2d bit(s) will not be transmitted.", (MAX_INCORRECT_CONTROL_WORD_SIZE - num_dummy_control_seq));
        //$display("[%0t]: Data Stream (binary)   = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[(INPUT_SHIFT_REG_SIZE-1)-:num_dummy_control_seq_reg], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
        $display("[%0t]: Write Test %2d: Starting Data Stream to DUT.", $realtime, current_write_test_num);
      end

      //data_out_reg = {<<{data_out_reg}}; // bit reversed (not required now since I am sending out MSB as input to DUT)

      // Get rid of excess "incorrect_control_signal" bits, as that is full size (MAX_INCORRECT_CONTROL_WORD_SIZE) instead of num_dummy_control_seq.
      data_out_reg = data_out_reg << (MAX_INCORRECT_CONTROL_WORD_SIZE-num_dummy_control_seq);


      if (DEBUG_LEVEL > 2) begin
        $display("[%0t]: Data Stream after shift (binary) = %b__%b__%b__%b_%b_%b_%b__%b_%b_%b_%b", $realtime, data_out_reg[(INPUT_SHIFT_REG_SIZE-1)-:MAX_INCORRECT_CONTROL_WORD_SIZE], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1)-:8], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8)-:1], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4)-:4], data_out_reg[(INPUT_CONTROL_DATA_SIZE-1-8-1-4-4-4-4-4-4-4)-:4]);
        $display("[%0t]: data_out_reg = %h", $realtime, data_out_reg);
        $display("[%0t]: data_out_reg << 1 = %h", $realtime, data_out_reg<<1);
      end


      load_din_shift_reg = 'b1;

      if (DEBUG_LEVEL > 2) begin
        $display("[%0t]: din_shift_reg = %h", $realtime, din_shift_reg);
        $display("[%0t]: din_shift_reg << 1 = %h", $realtime, din_shift_reg<<1);
      end


      t_n_cycle_clk_delay(1);

      load_din_shift_reg = 'b0;
      data_out_reg = 'd0;
      din_1_bin = 'b0;
      din_1_bcd = 'b0;
      din_2_bin = 'b0;
      din_2_bcd = 'b0;
      expected_dout_bcd = 'b0;
      correct_control_data = 'b0;
      incorrect_control_signal = 'b0;
      temp = 'b0;
      op = 'b0;

      t_n_cycle_clk_delay(shift_reg_size-1);

      if (DEBUG_LEVEL > 0) begin
        $display("[%0t]: Write Test %2d: Data Sent to DUT.", $realtime, current_write_test_num);
        $display("");
      end

      current_write_test_num = current_write_test_num + 'b1;

      `ifdef BREAK_BETWEEN_TESTS
        t_n_cycle_clk_delay(2);
      `endif

    end
  endtask : t_run_single_test

  task t_run_n_tests;
    input integer N;
    begin
      repeat(N) begin
        add_sub_select = $random;
        t_run_single_test(add_sub_select);
      end
    end
  endtask : t_run_n_tests

  // Task to wait for at least 150 cycles after end of test
  // Waits for additional time if current_read_test_num != NUM_TEST_VECTORS
  task t_end_test_wait;
    begin
      t_n_cycle_clk_delay(150);
      fork
        begin
          t_n_cycle_clk_delay(NUM_TEST_VECTORS * RESULT_WDT_MAX_VAL);
        end
        begin
          while (current_read_test_num != NUM_TEST_VECTORS) begin
            t_n_cycle_clk_delay(1);
          end
        end
      join_any
    end
  endtask : t_end_test_wait


  // Task to display test results
  task t_display_result;
    begin
      $display("");
      $display("");
      $display("[T=%09t] Info: Number of Tests configured    = %6d", $realtime, NUM_TEST_VECTORS);
      $display("[T=%09t] Info: Number of Transmitted packets = %6d", $realtime, current_write_test_num);
      $display("[T=%09t] Info: Number of Received packets    = %6d", $realtime, current_read_test_num);
      $display("[T=%09t] Info: Number of Tests Pass          = %6d", $realtime, num_tests_pass);
      $display("[T=%09t] Info: Number of Tests Fail          = %6d", $realtime, num_tests_fail);
      $display("");
      $display("");
      $display("");
    end
  endtask





  initial begin
    t_initialize_test();
    t_reset_tb_regs();
    t_assert_tb_reset();

    t_run_n_tests(NUM_TEST_VECTORS);

    t_end_test_wait();
    t_display_result();

    $finish;
  end




  // Clock Gen
  always begin
    #CLK_HALF_PERIOD;
    clock = ~clock;
  end // clk_gen

  always_ff @(posedge clock) begin : proc_din_shift_reg
    if (load_din_shift_reg) begin
      din_shift_reg <= data_out_reg;
    end else begin
      din_shift_reg <= din_shift_reg << 1;
    end
  end

  assign din = din_shift_reg[INPUT_SHIFT_REG_SIZE-1];
  
  always_ff @(posedge clock) begin : proc_dout_shift_reg
    dout_shift_reg <= {dout_shift_reg[(OUTPUT_CONTROL_DATA_SIZE-2):0], result};

    
      if ((observe_output) && (dout_shift_reg[(OUTPUT_CONTROL_DATA_SIZE-1) -: 8] == 8'h96)) begin
        if (DEBUG_LEVEL > 1) begin
          $display("");
          $display("[%0t]: >>>> Read Control Sequence Observed. Current Read = %d", $realtime, current_read_test_num);
        end

        dout_shift_reg <= {{(OUTPUT_CONTROL_DATA_SIZE-1){1'b0}}, result};

        if (dout_shift_reg == expected_data[current_read_test_num]) begin
          if (DEBUG_LEVEL > 0) begin
            $display("");
            $display("[%0t]: >>>> Current Read = %d", $realtime, current_read_test_num);
            $display("[%0t]: >>>> Expected Data = 0x%h_%h", $realtime, expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1 -: 8], expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
            $display("[%0t]: >>>> Read Data     = 0x%h_%h", $realtime, dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1 -: 8], dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
            $display("[%0t]: >>>> Read Number %2d: Test Pass.", $realtime, current_read_test_num);
            $display("");
          end
          num_tests_pass = num_tests_pass + 1;
        end else begin
          if (DEBUG_LEVEL > 0) begin
            $display("[%0t]: >>>> Read Number %2d: Expected Data = 0x%h_%h", $realtime, current_read_test_num, expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1 -: 8], expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
            $display("[%0t]: >>>> Read Number %2d: Read Data     = 0x%h_%h", $realtime, current_read_test_num, dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1 -: 8], dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
            $display("[%0t]: >>>> Read Number %2d: Test Fail (bad data).", $realtime, current_read_test_num);
            $display("");
          end
          num_tests_fail = num_tests_fail + 1;
        end

        current_read_test_num <= current_read_test_num + 'b1;
      end

      // A second set of input was completely transmitted before the output of previous input was received.
      if ((current_write_test_num > (current_read_test_num + 1)) || (result_wdt == 0)) begin
        if (DEBUG_LEVEL > 0) begin
          $display("[%0t]: >>>> Read Number %2d: RESULT TIMEOUT.", $realtime, current_read_test_num);
          if (DEBUG_LEVEL > 1) begin
            $display("[%0t]: >>>> Current Write Test Number = %d", $realtime, current_write_test_num);
            $display("[%0t]: >>>> Current Read Test Number  = %d", $realtime, current_read_test_num);
            $display("[%0t]: >>>> Current Watchdog Timer    = %d", $realtime, result_wdt);
            $display("[%0t]: >>>> Expected Data = 0x%h_%h", $realtime, expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1 -: 8], expected_data[current_read_test_num][OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
            $display("[%0t]: >>>> Read Data     = 0x%h_%h", $realtime, dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1 -: 8], dout_shift_reg[OUTPUT_CONTROL_DATA_SIZE-1-8 : 0]);
          end
          $display("[%0t]: >>>> Read Number %2d: Test Fail (timeout).", $realtime, current_read_test_num);
        end

        if (DEBUG_LEVEL > 1) begin
          $display("[%0t]: >>>> Watchdog Timer being reset.", $realtime);
        end

        current_read_test_num <= current_read_test_num + 'b1;
        num_tests_fail = num_tests_fail + 1;
        result_wdt <= RESULT_WDT_MAX_VAL;

      end else if (observe_output) begin
        result_wdt <= result_wdt - 'd1;
      end else begin
        result_wdt <= RESULT_WDT_MAX_VAL;
      end
  end

  always_comb begin
    if (current_write_test_num != current_read_test_num) begin
      observe_output = 'b1;
    end else begin
      observe_output = 'b0;
    end
  end


endmodule : Project3_tb_ex


