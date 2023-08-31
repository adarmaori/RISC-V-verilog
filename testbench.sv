module tb;
    reg clk;
    top PROCESSOR(clk);
    initial begin
        clk = 0;
        #1000 $finish;
    end
    always #5 clk = ~clk;
endmodule : tb