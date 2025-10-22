`timescale 1ns/1ps

// Simple exhaustive-style testbench for Project2
// Faster and more verbose: reduced sweeps via stride and detailed progress prints.
// Keeps input ordering simple and avoids complex delay/permutation machinery.

module project_2_tb;
    // DUT ports
    reg         reset_n;
    reg         clock;
    reg  [7:0]  d_in;
    reg  [1:0]  op;
    reg         capture;
    wire [8:0]  result;
    wire        valid;

    // Instantiate DUT
    Project2 dut (
        .reset_n(reset_n),
        .clock  (clock),
        .d_in   (d_in),
        .op     (op),
        .capture(capture),
        .result (result),
        .valid  (valid)
    );

    // Clock gen: 100 MHz
    localparam CLOCK_PERIOD = 10; // ns
    initial begin
        clock = 1'b0;
        forever #(CLOCK_PERIOD/2) clock = ~clock;
    end

    // Operand encodings
    localparam [1:0] A = 2'b00,
                     B = 2'b01,
                     C = 2'b10,
                     D = 2'b11;

    integer i;
    integer total_tests, pass_count, fail_count;

    // Global verbosity control (set to 0 during heavy sweeps)
    reg g_verbose;

    // Optional heavy sum-space sweep controls via plusargs
    // +sum_sweep            -> enable sum-space sweep
    // +sum_stride=<n>       -> stride for sums (default 4; set 1 for full 511x511)
    integer sum_stride;
    integer tmp_stride;
    reg     do_sum_sweep;
    localparam integer SUM_STRIDE_DEFAULT = 1;

    // Speed knob: test every SWEEP_STRIDE value instead of every value (1 = full exhaustive)
    localparam integer SWEEP_STRIDE = 1; // set to 1 for full 256-value sweeps; 16 keeps it fast
    localparam integer WAIT_TIMEOUT_CYCLES = 8; // shorter timeout for faster feedback

    // Compute expected 9-bit unsigned wrap-around result: (A+B) - (C+D)
    function [8:0] expected9;
        input [7:0] a, b, c, d;
        reg   [9:0] tmp; // allow one extra bit to capture range [-510..510]
    begin
        // Zero-extend to 10 bits then do math; lower 9 bits are the DUT's unsigned output domain (mod 512)
        tmp = {2'b00, a} + {2'b00, b} - {2'b00, c} - {2'b00, d};
        expected9 = tmp[8:0];
    end
    endfunction

    // Produce a pair of 8-bit values (x,y) whose sum equals s (0..510)
    function [15:0] pair_for_sum;
        input [8:0] s;
        reg [7:0] x, y;
    begin
        if (s <= 9'd255) begin
            x = s[7:0];
            y = 8'd0;
        end else begin
            x = 8'd255;
            y = s - 9'd255;
        end
        pair_for_sum = {x, y};
    end
    endfunction

    // Drive one operand value on the next rising edge (one-cycle capture pulse)
    task send_operand;
        input [7:0] val;
        input [1:0] which;
        begin
            @(negedge clock);
            d_in   <= val;
            op     <= which;
            capture <= 1'b1;
            if (g_verbose) begin
                case (which)
                    A: $display("[%0t] CAPTURE: A = %0d", $time, val);
                    B: $display("[%0t] CAPTURE: B = %0d", $time, val);
                    C: $display("[%0t] CAPTURE: C = %0d", $time, val);
                    D: $display("[%0t] CAPTURE: D = %0d", $time, val);
                endcase
            end
            @(posedge clock); // captured here
            @(negedge clock);
            capture <= 1'b0;  // drop capture between operands
        end
    endtask

    // Reset synchronous active-low for one cycle
    task do_reset;
        begin
            @(negedge clock);
            reset_n <= 1'b0;
            d_in    <= 8'd0;
            op      <= A;
            capture <= 1'b0;
            if (g_verbose) $display("[%0t] RESET: Asserting synchronous active-low reset", $time);
            @(posedge clock); // synchronous reset
            @(negedge clock);
            reset_n <= 1'b1;
            if (g_verbose) $display("[%0t] RESET: Deasserted", $time);
        end
    endtask

    // Perform a full operation by sending A, B, C, D values in fixed order on consecutive cycles
    task run_once;
        input [7:0] a, b, c, d;
        reg   [8:0] exp;
        integer     timeout;
        begin
            total_tests = total_tests + 1;

            do_reset();

            // Four back-to-back captures (allowed per spec: at least 0 cycle delay between inputs)
            if (g_verbose) $display("[%0t] RUN: A=%0d B=%0d C=%0d D=%0d", $time, a, b, c, d);
            send_operand(a, A);
            send_operand(b, B);
            send_operand(c, C);
            send_operand(d, D);

            // Wait for valid (expect within 1 cycle, but allow generous timeout)
            exp = expected9(a, b, c, d);
            timeout = 0;
            if (g_verbose) $write("[%0t] WAIT: for VALID", $time);
            while (!valid && timeout < WAIT_TIMEOUT_CYCLES) begin
                @(posedge clock);
                timeout = timeout + 1;
                if (g_verbose) $write(".");
            end
            if (g_verbose) $display("");

            if (valid && result === exp) begin
                if (g_verbose)
                    $display("[%0t] PASS: result=%0d (expected=%0d) waited=%0d cycles", $time, result, exp, timeout);
                pass_count = pass_count + 1;
            end else begin
                if (g_verbose)
                    $display("[%0t] FAIL: A=%0d B=%0d C=%0d D=%0d | expected=%0d got=%0d (valid=%b, waited %0d cycles)",
                             $time, a, b, c, d, exp, result, valid, timeout);
                fail_count = fail_count + 1;
            end

            // Advance a couple cycles to clear valid if it pulses
            repeat (2) @(posedge clock);
        end
    endtask

    // Main stimulus
    initial begin
    // Init
        reset_n   = 1'b1; // will be asserted low by do_reset task
        d_in      = 8'd0;
        op        = A;
        capture   = 1'b0;
        total_tests = 0;
        pass_count  = 0;
        fail_count  = 0;
    g_verbose   = 1'b1;

    // Configure heavy sweep options from plusargs
    do_sum_sweep = 1'b1; // enable max coverage by default
        sum_stride   = SUM_STRIDE_DEFAULT;
        if ($test$plusargs("sum_sweep")) do_sum_sweep = 1'b1;
        if ($value$plusargs("sum_stride=%d", tmp_stride)) sum_stride = tmp_stride;

        // Give some clocks before starting
        repeat (3) @(posedge clock);

        $display("\n==== Project2 Fast/Verbose TB ====");
        $display("Stride=%0d (1=full 256), Timeout=%0d cycles", SWEEP_STRIDE, WAIT_TIMEOUT_CYCLES);

        // Phase 1: Exhaustive A sweep (B=C=D=0)
        $display("\n-- Phase 1: Sweep A (B=C=D=0) --");
        for (i = 0; i < 256; i = i + SWEEP_STRIDE) begin
            run_once(i[7:0], 8'd0, 8'd0, 8'd0);
        end

        // Phase 2: Exhaustive B sweep (A=C=D=0)
        $display("\n-- Phase 2: Sweep B (A=C=D=0) --");
        for (i = 0; i < 256; i = i + SWEEP_STRIDE) begin
            run_once(8'd0, i[7:0], 8'd0, 8'd0);
        end

        // Phase 3: Exhaustive C sweep (A=B=D=0) - exercises unsigned underflow wrap
        $display("\n-- Phase 3: Sweep C (A=B=D=0) --");
        for (i = 0; i < 256; i = i + SWEEP_STRIDE) begin
            run_once(8'd0, 8'd0, i[7:0], 8'd0);
        end

        // Phase 4: Exhaustive D sweep (A=B=C=0)
        $display("\n-- Phase 4: Sweep D (A=B=C=0) --");
        for (i = 0; i < 256; i = i + SWEEP_STRIDE) begin
            run_once(8'd0, 8'd0, 8'd0, i[7:0]);
        end

        // Phase 5: Targeted edge/mixed cases
        $display("\n-- Phase 5: Edge/Mixed cases --");
        run_once(8'd255, 8'd255, 8'd0,   8'd0);   // max positive: 510
        run_once(8'd0,   8'd0,   8'd255, 8'd255); // max negative -> wrap to 2
        run_once(8'd200, 8'd100, 8'd150, 8'd50);  // 300-200 = 100
        run_once(8'd1,   8'd0,   8'd0,   8'd1);   // 1-1 = 0
        run_once(8'd255, 8'd0,   8'd0,   8'd1);   // 255-1 = 254
        run_once(8'd0,   8'd255, 8'd1,   8'd0);   // 255-1 = 254

        // Simple order-independence smoke checks (same values, different send orders)
        // Note: The DUT should produce the same result regardless of input order.
        // We'll reuse send task directly for two permutations.
        begin : order_checks
            reg [7:0] a,b,c,d;
            reg [8:0] exp;
            integer    timeout;

            a = 8'd10; b = 8'd20; c = 8'd5; d = 8'd6; // exp = 30 - 11 = 19
            exp = expected9(a,b,c,d);

            // Order 1: A,B,C,D
            do_reset();
            send_operand(a, A);
            send_operand(b, B);
            send_operand(c, C);
            send_operand(d, D);
            timeout = 0; while (!valid && timeout < 20) begin @(posedge clock); timeout = timeout + 1; end
            if (!(valid && result === exp)) begin
                $display("[%0t] FAIL: Order ABCD expected=%0d got=%0d", $time, exp, result);
                fail_count = fail_count + 1; total_tests = total_tests + 1;
            end else begin
                $display("[%0t] PASS: Order ABCD result=%0d", $time, result);
                pass_count = pass_count + 1; total_tests = total_tests + 1;
            end
            repeat (2) @(posedge clock);

            // Order 2: D,C,B,A
            do_reset();
            send_operand(d, D);
            send_operand(c, C);
            send_operand(b, B);
            send_operand(a, A);
            timeout = 0; while (!valid && timeout < 20) begin @(posedge clock); timeout = timeout + 1; end
            if (!(valid && result === exp)) begin
                $display("[%0t] FAIL: Order DCBA expected=%0d got=%0d", $time, exp, result);
                fail_count = fail_count + 1; total_tests = total_tests + 1;
            end else begin
                $display("[%0t] PASS: Order DCBA result=%0d", $time, result);
                pass_count = pass_count + 1; total_tests = total_tests + 1;
            end
            repeat (2) @(posedge clock);
        end

        // Phase 6: Optional Sum-space sweep (A+B vs C+D) across sums 0..510
        if (do_sum_sweep) begin : sum_sweep
            integer s1, s2;
            integer local_count;
            reg [15:0] ab, cd;
            $display("\n-- Phase 6: Sum-space sweep ENABLED -- stride=%0d (use +sum_stride=1 for full 511x511) --", sum_stride);
            g_verbose = 1'b0; // quiet during heavy loop
            local_count = 0;
            for (s1 = 0; s1 <= 510; s1 = s1 + sum_stride) begin
                for (s2 = 0; s2 <= 510; s2 = s2 + sum_stride) begin
                    ab = pair_for_sum(s1[8:0]);
                    cd = pair_for_sum(s2[8:0]);
                    run_once(ab[15:8], ab[7:0], cd[15:8], cd[7:0]);
                    local_count = local_count + 1;
                    if ((local_count % 2000) == 0) begin
                        $display("[%0t] Sum-sweep progress: %0d tests so far (total=%0d, fails=%0d)",
                                 $time, local_count, total_tests, fail_count);
                    end
                end
                $display("[%0t] Sum-sweep row s1=%0d complete (global total=%0d)", $time, s1, total_tests);
            end
            g_verbose = 1'b1; // restore verbosity
        end

        $display("\n==== SUMMARY ====\nTotal tests: %0d\nPass: %0d\nFail: %0d\n", total_tests, pass_count, fail_count);
        $finish;
    end

endmodule
