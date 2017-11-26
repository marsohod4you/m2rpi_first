
module m2rpi(
	input wire OSC,
	input wire [2:0]KEY,
	output wire [3:0]LED,
	inout wire [27:0]GPIO_A,
	inout wire [27:0]GPIO_B,
	
	//Raspberry GPIO pins
	input wire GPIO0,
	input wire GPIO1,
	input wire GPIO2,
	input wire GPIO3,
	input wire GPIO4,
	input wire GPIO5,
	input wire GPIO6,
	input wire GPIO7,
	input wire GPIO8,
	input wire GPIO9,
	input wire GPIO10,
	input wire GPIO11,
	input wire GPIO12,
	input wire GPIO13,
	input wire GPIO14, //Serial RX
  output wire GPIO15, //Serial TX
	input wire GPIO16,
	input wire GPIO17,
	input wire GPIO18,
	input wire GPIO19,
	input wire GPIO20,
	input wire GPIO21,
	input wire GPIO22,
	input wire GPIO23,
	input wire GPIO24,
	input wire GPIO25,
	input wire GPIO26,
	input wire GPIO27
	);
	
wire w_clk;
wire w_clk1;
wire w_locked;

pll my_pll_inst(
	.inclk0(OSC ),
	.c0( w_clk  ),
	.c1( w_clk1 ),
	.locked( w_locked )
	);
	
reg [31:0]counter;
always @( posedge w_clk )
begin
	if( KEY[0]==1'b0 )
		counter <= 0;
	else
	if( KEY[1]==1'b1 )
		counter <= counter+1;
end

wire [7:0]rx_byte;
wire w_rbyte_ready;
serial my_serial_inst(
	.reset( ~w_locked ),
	.clk100( w_clk ),
	.rx( GPIO14 ),
	.rx_byte( rx_byte ),
	.rbyte_ready( w_rbyte_ready )
	);

//registered delay of w_rbyte_ready impulse 
reg [1:0]r_rbyte_ready;
always @( posedge w_clk )
	r_rbyte_ready <= { r_rbyte_ready[0], w_rbyte_ready };

//fix received serial byte into register
reg [7:0]r_rx_byte;
always @( posedge w_clk )
	if( w_rbyte_ready )
		r_rx_byte <= rx_byte;

//modify received byte +1 and fix into register
reg [7:0]r_rx_byte_1;
always @( posedge w_clk )
	if( r_rbyte_ready[0] )
		r_rx_byte_1 <= r_rx_byte+1'b1;

//serial send to raspberry modified byte
tx_serial my_tx_serial_inst(
	.reset( ~w_locked ),
	.clk100( w_clk ),
	.sbyte( r_rx_byte_1 ),
	.send( r_rbyte_ready[1] ),
	.tx( GPIO15 ), //raspberry serial TX
	.busy() 
	);

assign LED = r_rx_byte[1:0]==2'b00 ? counter[27:24] : 
				 r_rx_byte[1:0]==2'b01 ? counter[26:23] : 
				 r_rx_byte[1:0]==2'b10 ? counter[25:22] : counter[24:21];

endmodule
