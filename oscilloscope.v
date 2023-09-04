module oscilloscope (clk, txd, clk_flash, data_flash);

input clk;
output txd;
input clk_flash;
input [7:0] data_flash;

reg [7:0] data_flash_reg;
always @(posedge clk_flash) begin
    data_flash_reg <= data_flash_reg;
end

wire [7:0] q_fifo;
fifo my_fifo (.data(data_flash_reg), 
                .wrreq(wrreq),
                .wrclk(wrclk),
                .wrfull(wrfull),
                .wrempty(wrempty),
                .q(q_fifo),
                .rdreq(dreq),
                .rdclk(clk),
                .rdempty(rdempty));

//The flash ADC side starts filling the FIFO only when it is completely empty
//and stops when it is full, and then waits until it is completely empty again
reg fill_fifo;
always @(posedge clk_flash) begin
    if(~fill_fifo)
        fill_fifo <= wrempty;   //start when empty
    else
        fill_fifo <= ~wrfull;   //stop when full
end

assign wrreq = fill_fifo;

//The manager side sends when the FIFO is not empty
wire txd_busy;
wire txd_start = ~txd_busy & ~rdempty;
assign rdreq = txd_start;

async_transmitter uut (.clk(clk),
                        .txd(txd),
                        .txd_start(txd_start),
                        .txd_busy(txd_busy),
                        .txd_data(txd_data));

endmodule
