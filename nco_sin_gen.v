/*
	В проекте есть задержки распространения сигнала и стоит бы попробоват поставить срабатываание событий по спаду тактового синхроимпульса в 
	алвейсе для каунта
*/

module nco_sin_gen
#(parameter WIDTH_ADDR = 16, parameter HEIGHT_ADDR = 16)
(
	input i_clk,
	input [3:0] sw,
	output i_clk_to_dac,
	output reg [13:0] dac_in
);

	reg [15:0] sine_rom [(2**HEIGHT_ADDR-1):0];
	wire clock;
	reg [31:0] cnt;
	
	 my_pll my_pll_inst(
				.inclk0(i_clk),
				.c0(clock));
				
	assign i_clk_to_dac = ~clock;

	initial begin 
		$readmemh("sine_rom.hex", sine_rom);
	end

	always @(posedge clock) begin
		dac_in <= sine_rom[cnt[31:16]];
	end
	
	always @(posedge clock) begin
		cnt <= cnt + (sw << 22);
	end

	
endmodule

/*
	Счетчик меняет свой шаг счета за счет 4 переключателей [3:0] sw, которые в свою очередь записываються в 22 по 25 
	бит в регистр cnt, следовательно в зависимости от того какой переключатель включен, шаг будет увеличиваться или 
	уменьшаться, а занчит частота будет соответственно увеличиваться или уменьшаться. Расчитаем частоты, которые 
	будут при всех возможных комбинациях вкл/выкл переключателей.(помнить что в этом случае значение переключателей
	записываеться в биты регистра cnt c 22 по 25, формула для вычисления частоты f =  (step/(2^N))*f0,
	N - розрядность регистра счета(cnt), f0 - частота тактирования, в нашем случае N = 32, f0 = 50 МГц).
	sw = 0000 => f = 0;
	sw = 0001 => f = 48.8 kHz
	sw = 0010 => f = 97.7 kHz
	sw = 0011 => f = 146.48kHz
	sw = 0100 => f = 195.312kHz
	sw = 0101 => f = 244.14kHz
	sw = 0110 => f = 292.968kHz
	sw = 0111 => f = 341.796kHz
	sw = 1000 => f = 390.625kHz
	sw = 1001 => f = 439.453kHz
	sw = 1010 => f = 488.253kHz
	sw = 1011 => f = 537.053kHz
	sw = 1100 => f = 585.853kHz
	sw = 1101 => f = 634.653kHz
	sw = 1110 => f = 683.453kHz
	sw = 1111 => f = 732.421kHz
	
	Если мы хотим сделать фильтр с fcut_off > 5MHz, то необходимо записывать значения sw в биты с 25 по 28 регистра 
	cnt, тогда максимально возможная частота(когда все переключатели включены) составляет f = 5.86MHz.
*/