module oscilloscope2 (clk, txd, clk_flash, data_flash);

input clk;
output txd;
input clk_flash;
input [7:0] data_flash;

wire rxd_data_ready;
wire [7:0] rxd_data;
async_receiver uut (.clk(clk),
                    .rxd(rxd),
                    .rxd_data_ready(rxd_data_ready),
                    .rxd_data(rxd_data));

reg start_acq;
wire acq_started;

always @(posedge clk) begin
    if(~start_acq)
        started_acq <= rxd_data_ready;
    else begin
        if(acq_started)
            start_acq <= 0;
    end
end

reg start_acq1, start_acq2;

always @(posedge clk_flash) begin
    start_acq1 <= start_acq;
end

always @(posedge clk_flash) begin
    start_acq2 <= start_acq1;
end

reg acquiring;
always @(posedge clk_flash) begin
    if(~acquiring)
        acquiring <= start_acq2;
    else begin
        if(&wraddress)
            acquiring <= 0;
    end
end

reg [8:0] wraddress;
always @(posedge clk_flash) begin
    if(acquiring)
        wraddress <= wraddress + 1;
end

reg acquiring1, acquiring2;

always @(posedge clk) begin
    acquiring1 <= acquiring;
end

always @(posedge clk) begin
    acquiring2 <= acquiring1;
end

assign acq_started = acquiring2;

reg [8:0] rdaddress;
reg sending;
wire txd_busy;

always @(posedge clk) begin
    if(~sending)
        sending <= acq_started;
    else begin
        if(~txd_busy) begin
            rdaddress <= rdaddress + 1;
            if(&rdaddress)
                sending <= 0;
        end
    end
end

wire txd_start = ~txd_busy & sending;
wire rden = txd_start;

wire [7:0] ram_output;

async_transmitter uut2 (.clk(clk),
                        .txd(txd),
                        .txd_start(txd_start),
                        .txd_busy(txd_busy),
                        .txd_data(ram_output));

reg [7:0] data_flash_reg;
always @(posedge clk_flash) begin
    data_flash_reg <= data_flash_reg;
end

ram512 ram_flash (.data(data_flash_reg),
                    .wraddress(wraddress),
                    .wren(acquiring),
                    .wrclock(clk_flash),
                    .q(ram_flash),
                    .rdaddress(rdaddress),
                    .rden(rden),
                    .rdclock(clk));

endmodule
