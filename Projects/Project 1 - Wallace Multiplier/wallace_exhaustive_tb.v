module wallace_8x8_tb;

    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [15:0] prod;
    
    // Expected result for comparison
    reg [15:0] expected_prod;
    
    // Test counters
    integer i, j;
    integer error_count;
    integer test_count;
    
    // File handle for logging errors
    integer error_file;
    
    // Instantiate the Unit Under Test (UUT)
    wallace_8x8 uut (
        .a(a),
        .b(b),
        .prod(prod)
    );
    
    // Test process
    initial begin
        // Initialize test variables
        error_count = 0;
        test_count = 0;
        
        // Open error log file
        error_file = $fopen("wallace_errors.log", "w");
        
        // Display test header
        $display("========================================");
        $display("Starting Exhaustive Wallace 8x8 Multiplier Test");
        $display("Testing all %0d combinations", 256*256);
        $display("========================================");
        $display("Time\t\ta\t\tb\t\tExpected\tGot\t\tStatus");
        $display("------------------------------------------------------------------------");
        
        // Exhaustive testing - all possible combinations
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                // Apply test inputs
                a = i[7:0];
                b = j[7:0];
                
                // Calculate expected result
                expected_prod = i * j;
                
                // Wait for combinational logic to settle
                #10;
                
                // Increment test counter
                test_count = test_count + 1;
                
                // Check if the result matches expected
                if (prod !== expected_prod) begin
                    error_count = error_count + 1;
                    
                    // Display error
                    $display("%0t:\ta=%3d (0x%02X)\tb=%3d (0x%02X)\tExp=%5d (0x%04X)\tGot=%5d (0x%04X)\tERROR", 
                             $time, a, a, b, b, expected_prod, expected_prod, prod, prod);
                    
                    // Log error to file
                    $fwrite(error_file, "Error at time %0t: a=%3d (0x%02X), b=%3d (0x%02X), Expected=%5d (0x%04X), Got=%5d (0x%04X)\n",
                            $time, a, a, b, b, expected_prod, expected_prod, prod, prod);
                end else begin
                    // Optional: Display every Nth test to show progress
                    if (test_count % 1000 == 0) begin
                        $display("%0t:\ta=%3d (0x%02X)\tb=%3d (0x%02X)\tExp=%5d (0x%04X)\tGot=%5d (0x%04X)\tPASS", 
                                 $time, a, a, b, b, expected_prod, expected_prod, prod, prod);
                    end
                end
                
                // Optional: Add a small delay between tests
                #1;
            end
            
            // Display progress every 16 iterations of i (roughly every 6.25%)
            if (i % 16 == 0 && i != 0) begin
                $display("Progress: %0d%% complete (%0d/%0d tests)", 
                         (i*100)/256, i*256, 256*256);
            end
        end
        
        // Close error file
        $fclose(error_file);
        
        // Display final test results
        $display("========================================");
        $display("Test Complete!");
        $display("Total tests run: %0d", test_count);
        $display("Errors found: %0d", error_count);
        $display("Pass rate: %0.2f%%", (test_count - error_count) * 100.0 / test_count);
        
        if (error_count == 0) begin
            $display("SUCCESS: All tests passed!");
        end else begin
            $display("FAILURE: %0d errors detected", error_count);
            $display("See 'wallace_errors.log' for details");
        end
        
        $display("========================================");
        
        // Test some specific corner cases with detailed output
        $display("\nTesting specific corner cases:");
        $display("------------------------------------------------------------------------");
        
        // Test case 1: 0 x 0
        a = 8'd0; b = 8'd0; #10;
        $display("0 x 0 = %d (Expected: 0) - %s", prod, (prod == 16'd0) ? "PASS" : "FAIL");
        
        // Test case 2: 255 x 255 (max values)
        a = 8'd255; b = 8'd255; #10;
        $display("255 x 255 = %d (Expected: 65025) - %s", prod, (prod == 16'd65025) ? "PASS" : "FAIL");
        
        // Test case 3: 1 x 255
        a = 8'd1; b = 8'd255; #10;
        $display("1 x 255 = %d (Expected: 255) - %s", prod, (prod == 16'd255) ? "PASS" : "FAIL");
        
        // Test case 4: Powers of 2
        a = 8'd128; b = 8'd2; #10;
        $display("128 x 2 = %d (Expected: 256) - %s", prod, (prod == 16'd256) ? "PASS" : "FAIL");
        
        // Test case 5: 16 x 16
        a = 8'd16; b = 8'd16; #10;
        $display("16 x 16 = %d (Expected: 256) - %s", prod, (prod == 16'd256) ? "PASS" : "FAIL");
        
        $display("========================================\n");
        
        // End simulation
        $finish;
    end
    
    // Optional: Timeout to prevent infinite simulation
    initial begin
        #10000000; // Adjust timeout as needed
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Optional: Generate VCD file for waveform viewing
    initial begin
        $dumpfile("wallace_8x8_tb.vcd");
        $dumpvars(0, wallace_8x8_tb);
    end

endmodule
