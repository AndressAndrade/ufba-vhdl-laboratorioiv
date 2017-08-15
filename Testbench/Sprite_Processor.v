

module Sprite_Processor(
	
	R_in,
	G_in,
	B_in,
	clk,
	rst,
	data_in,
	H_pos_in,
	V_pos_in,
	
	R_out,
	G_out,
	B_out,
	wren_out,
	addr_out,
	level_count,
	EstadoAtual_FSM1,	//SAIDA PARA TESTBENCH
	//EstadoAtual_FSM2	//SAIDA PARA TESTBENCH
	teste1,
	teste2
);


	input clk;
	input rst;
	input	[7:0]		R_in;
	input	[7:0]		G_in;
	input	[7:0]		B_in;
	input	[9:0]		H_pos_in;
	input	[9:0]		V_pos_in;
	input	[15:0]	data_in;
	
	output						wren_out;
	output	[7:0]		R_out;
	output	[7:0]		G_out;
	output	[7:0]		B_out;
	output	reg	[15:0]	addr_out;
	output	reg	[6:0]		level_count;	//SAIDA PARA TESTBENCH

	output	[9:0]		teste1;	//SAIDA PARA TESTBENCH
	output	reg	[9:0]		teste2;	//SAIDA PARA TESTBENCH
	
	reg [6:0]	level_count_aux;
	reg [15:0]	ram_addr;
	reg [15:0]	ram_addr_aux;
	
	reg [5:0]	sprite_id		[0:63];
	reg [9:0]	sprite_x			[0:63];
	reg [9:0]	sprite_y			[0:63];
	reg [15:0]	sprite_color	[0:63];
	
	reg [15:0]	line_A_shape	[0:63];
	reg [15:0]	line_B_shape	[0:63];
	reg			line_flag;
	
	parameter	line_A	= 1'b0;
	parameter	line_B	= 1'b1;
	
	reg [6:0] i;

	
	assign wren_out = 1'b0;
	
	
	reg flag_loop;
	
	
	assign R_out = R_in;
	assign G_out = G_in;
	assign B_out = B_in;

	assign teste1[9:1] = 9'b000000000;
	assign teste1[0] = line_flag;
	
	
	/*################################################################*/
	/*############  MA�QUINA DE ESTADO 1							############*/
	/*############  													############*/
	/*############  LEITURA DOS PARA�METROS DOS SHAPES		############*/
	/*############  SALVOS NA DATA_SEGMENT_RAM				############*/
	/*################################################################*/
	
	output	reg	[3:0]		EstadoAtual_FSM1;
				reg	[3:0]		EstadoFuturo_FSM1;

	// Estados
	parameter	Reset_FSM1			= 4'b0000;	// Reset_FSM1			= 0
	parameter	Set_Address_Attr	= 4'b0001;	// Set_Address_Attr	= 1
	parameter	Read_Sprite_X		= 4'b0010;	// Read_Sprite_X		= 2
	parameter	Read_Sprite_Y		= 4'b0011;	// Read_Sprite_Y		= 3
	parameter	Read_Sprite_Color	= 4'b0100;	// Read_Sprite_Color	= 4
	parameter	Read_Sprite_ID		= 4'b0101;	// Read_Sprite_ID		= 5
	parameter	Wait_Line			= 4'b0110;	// Wait_Line			= 6
	parameter	Set_Line				= 4'b0111;	// Set_Line				= 7
	parameter	Set_Address_Shape	= 4'b1000;	// Set_Address_Shape	= 8
	parameter	Read_Shape			= 4'b1001;	// Read_Shape			= 9
	parameter	Change_Level		= 4'b1010;	// Change_Level		= 10
	
	// Decodificador de proximo estado
	always @ (V_pos_in, H_pos_in, ram_addr, level_count, EstadoAtual_FSM1)
	begin
		case (EstadoAtual_FSM1)
		
			Reset_FSM1:
			begin
				if(V_pos_in == 31 && H_pos_in == 0)
					EstadoFuturo_FSM1 = Set_Address_Attr;
					
				else
					EstadoFuturo_FSM1 = Reset_FSM1;
			end

			Set_Address_Attr:
			begin
				if(ram_addr >= 1024 && ram_addr <= 1087)
					EstadoFuturo_FSM1 = Read_Sprite_X;
					
				else if(ram_addr >= 1088 && ram_addr <= 1151)
					EstadoFuturo_FSM1 = Read_Sprite_Y;
				
				else if(ram_addr >= 1152 && ram_addr <= 1215)
					EstadoFuturo_FSM1 = Read_Sprite_Color;
					
				else if(ram_addr >= 1216 && ram_addr <= 1279)
					EstadoFuturo_FSM1 = Read_Sprite_ID;
			
				else
					EstadoFuturo_FSM1 = Wait_Line;
			end

			Read_Sprite_X:
			begin
				EstadoFuturo_FSM1 = Set_Address_Attr;
			end

			Read_Sprite_Y:
			begin
				EstadoFuturo_FSM1 = Set_Address_Attr;
			end

			Read_Sprite_Color:
			begin
				EstadoFuturo_FSM1 = Set_Address_Attr;
			end

			Read_Sprite_ID:
			begin
				EstadoFuturo_FSM1 = Set_Address_Attr;
			end
			
			Wait_Line:
			begin
				if(V_pos_in >= 32 && V_pos_in <= 511 && H_pos_in == 0)
					EstadoFuturo_FSM1 = Set_Line;
				else
					EstadoFuturo_FSM1 = Wait_Line;
			end
			
			Set_Line:
			begin
				if(V_pos_in >= sprite_y[level_count]-1 && V_pos_in <= sprite_y[level_count]+14)
					EstadoFuturo_FSM1 = Set_Address_Shape;
				else
					EstadoFuturo_FSM1 = Change_Level;
			end
			
			Set_Address_Shape:
			begin
				EstadoFuturo_FSM1 = Read_Shape;
			end
			
			Read_Shape:
			begin
				EstadoFuturo_FSM1 = Change_Level;
			end
			
			Change_Level:
			begin
				if(level_count < 64 && V_pos_in <= 511)
					EstadoFuturo_FSM1 = Set_Line;
				else if(level_count >= 64 && V_pos_in >= 511)
					EstadoFuturo_FSM1 = Reset_FSM1;
				else
					EstadoFuturo_FSM1 = Wait_Line;
			end
			
			default:
			begin
				EstadoFuturo_FSM1 = Reset_FSM1;
			end

		endcase

	end


	// Decodificador de saida
	always @ (EstadoAtual_FSM1)
	begin
		case (EstadoAtual_FSM1)
	
			Reset_FSM1:
			begin
				ram_addr = 1024;
				level_count = 63;
				addr_out = 16'hzzzz;
				line_flag = line_B;
			end
		
			Set_Address_Attr:
			begin
				addr_out = ram_addr;
				ram_addr_aux = ram_addr;
				
				if(level_count_aux < 63)
					level_count = level_count_aux + 1'b1;
				else
					level_count = 0;
			end
		
			Read_Sprite_X:
			begin
				sprite_x[level_count] = data_in[9:0];
				ram_addr = ram_addr_aux + 1'b1;
				level_count_aux = level_count;
			end
			
			Read_Sprite_Y:
			begin
				sprite_y[level_count] = data_in[9:0];
				ram_addr = ram_addr_aux + 1'b1;
				level_count_aux = level_count;
			end
			
			Read_Sprite_Color:
			begin
				sprite_color[level_count] = data_in[15:0];
				ram_addr = ram_addr_aux + 1'b1;
				level_count_aux = level_count;
			end
			
			Read_Sprite_ID:
			begin
				sprite_id[level_count] = data_in[5:0];
				ram_addr = ram_addr_aux + 1'b1;
				level_count_aux = level_count;
			end
			
			Wait_Line:
			begin
				level_count = 0;
				if (line_flag == line_A)
					line_flag = line_B;
				else
					line_flag = line_A;
			end
		
			Set_Line:
			begin
				level_count_aux = level_count;
			end
		
			Set_Address_Shape:
			begin
				addr_out = (sprite_id[level_count]*8'h10) + (V_pos_in - sprite_y[level_count]+1'b1);
			end
			
			Read_Shape:
			begin
				if(line_flag == line_A)
					line_A_shape[level_count] = data_in[15:0];
				else
					line_B_shape[level_count] = data_in[15:0];
			end
			
			Change_Level:
			begin
				level_count = level_count_aux + 1'b1;
			end
			
			default:
			begin
				ram_addr = 1024;
				level_count = 63;
				addr_out = 16'hzzzz;
				line_flag = line_B;
			end
	
		endcase
	end


	// Atualizacao de registrador de estado e logica de reset
	always @ (posedge clk)
	begin

		if (rst)
		begin
			EstadoAtual_FSM1	<= Reset_FSM1;
		end
	
		else
		begin
			EstadoAtual_FSM1	<=	EstadoFuturo_FSM1;
		end
	
	end

	/*################################################################*/
	/*################################################################*/	

	
	/*################################################################*/
	/*############  MA�QUINA DE ESTADO 2							############*/
	/*############  													############*/
	/*############  													############*/
	/*############  													############*/
	/*################################################################*/
	
	/*output	reg	[1:0]		EstadoAtual_FSM2;
				reg	[1:0]		EstadoFuturo_FSM2;

	// Estados
	parameter	Reset_FSM2		= 2'b00;	// Reset_FSM2		= 0
	parameter	Print_Line_A	= 2'b01;	// Print_Line_A	= 1
	parameter	Print_Line_B	= 2'b10;	// Print_Line_B	= 2
	
	// Decodificador de proximo estado
	always @ (V_pos_in, line_flag, EstadoAtual_FSM2)
	begin

		case (EstadoAtual_FSM2)
		
			Reset_FSM2: 
			begin
				if (V_pos_in >= 33 && V_pos_in <= 512)
				begin
					if (line_flag == line_B)
						EstadoFuturo_FSM2 = Print_Line_A;
					else
						EstadoFuturo_FSM2 = Print_Line_B;
				end
				
				else
					EstadoFuturo_FSM2 = Reset_FSM2;
				
			end
			
			Print_Line_A:
			begin
				EstadoFuturo_FSM2 = Reset_FSM2;
			end
		
			Print_Line_B:
			begin
				EstadoFuturo_FSM2 = Reset_FSM2;
			end
		
			default: 
			begin
				EstadoFuturo_FSM2 = Reset_FSM2;
			end
			
		endcase

	end
	
	// Decodificador de saida
	always @ (EstadoAtual_FSM2)
	begin
		
		
		case (EstadoAtual_FSM2)
			
			Reset_FSM2:
			begin
			
			end
			
			Print_Line_A:
			begin
				R_out = R_in;
				G_out = G_in;
				B_out = B_in;
				flag_loop = 1'b1;
				for(i=0;i<64;i=i+1)
				begin
					if( V_pos_in >= sprite_y[i] &&
						V_pos_in <= sprite_y[i] + 15 &&
						H_pos_in >= sprite_x[i] &&
						H_pos_in <= sprite_x[i] + 15 &&
						line_A_shape[i][H_pos_in-sprite_x[i]] &&
						flag_loop)
						
						begin
							R_out [2:0]	=	3'b000;
							R_out	[7:3]	=	sprite_color[i][4:0];
			
							G_out	[1:0]	=	2'b00;
							G_out	[7:2]	=	sprite_color[i][10:5];
			
							B_out	[2:0]	=	3'b000;
							B_out	[7:3]	=	sprite_color[i][15:11];
							
							flag_loop = 1'b0;
						end
				
				end
			end
			
			Print_Line_B:
			begin
				R_out = R_in;
				G_out = G_in;
				B_out = B_in;
				flag_loop = 1'b1;
				for(i=0;i<64;i=i+1)
				begin
					if(V_pos_in >= sprite_y[i] &&
						V_pos_in <= sprite_y[i] + 15 &&
						H_pos_in >= sprite_x[i] &&
						H_pos_in <= sprite_x[i] + 15 &&
						line_B_shape[i][H_pos_in-sprite_x[i]]&&
						flag_loop)
						
						begin
							R_out[2:0]	=	3'b000;
							R_out[7:3]	=	sprite_color[i][4:0];
			
							G_out[1:0]	=	2'b00;
							G_out[7:2]	=	sprite_color[i][10:5];
			
							B_out[2:0]	=	3'b000;
							B_out[7:3]	=	sprite_color[i][15:11];
							flag_loop = 1'b0;
						end
				
				end
			end
			
			
			default:
			begin
			
			end
		
		endcase
	
	end
	
	
	// Atualizacao de registrador de estado e logica de reset
	always @ (posedge clk)
	begin

		if (rst)
		begin
			EstadoAtual_FSM2	<= Reset_FSM2;
		end
	
		else
		begin
			EstadoAtual_FSM2	<= EstadoFuturo_FSM2;
		end
	
	end*/
	

endmodule