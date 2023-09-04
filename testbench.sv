module tb;
    reg clk;
    top PROCESSOR(clk);
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb); // This will dump all signals under the testbench hierarchy 'tb'
        clk = 0;
        #1000 $finish;
    end
    always #5 clk = ~clk;
endmodule : tb