module led_control(
    // Input clock to our panel driver
    input wire i_clk_i,

    input enable,

    output reg o_data_clock,
    output reg o_data_latch,
    output reg o_data_blank,
    // Data lines to be shifted
    output reg [1:0] o_data_r,
    output reg [1:0] o_data_g,
    output reg [1:0] o_data_b,

    output reg [1:0] o_data_r2,
    output reg [1:0] o_data_g2,
    output reg [1:0] o_data_b2,
    // Inputs to the row select demux
    output reg [4:0] o_row_select,

    output led,
    output requireData,
    input wr,
    input [35:0] dataLine1,
    input [35:0] dataLine2,
    input [11:0] addrWrite,
    input [29:0] RamTime
);
    
//------------Declaracion e inicializacion de parametros, registro y señales-------------------------
    // Pixeles por fila
    localparam pixels_per_row = 162;

    // IDs máquina de estados
    localparam
        S_UPDATE_DATA_ROW  = 0,
        S_BLANK_SET = 1,
        S_LATCH_SET = 2,
        S_INCREMENT_ROW = 3,
        S_LATCH_CLEAR = 4,
        S_BLANK_CLEAR = 5,
        S_INCREMENT_PWM = 6;

    // Reset que pausa Clk y máquina de estados
    wire i_clk;
    assign i_clk = i_clk_i & enable;

    //  Registros y senales de las memoria RAM
    reg [29:0] ramSelectCounter;
    reg ram1Select;
    reg ram2Select;
    reg [11:0] addrRead;
    wire [35:0] data1;
    wire [35:0] data2;
    wire [35:0] data;

    // registros de activacion de los pines RGB de HUB75
    reg [1:0] data_r = 0;
    reg [1:0] data_g = 0;
    reg [1:0] data_b = 0;

    reg [1:0] data_r2 = 0;
    reg [1:0] data_g2 = 0;
    reg [1:0] data_b2 = 0;

    //Registro del selector de columnas
    reg [4:0] w_o_row_select =0;

     //Registros de data para 4 pixeles
    reg red_register   = 0;
    reg green_register = 0;
    reg blue_register  = 0;
    reg red_register2   = 0;
    reg green_register2 = 0;
    reg blue_register2  = 0;

    reg red_register3   = 0;
    reg green_register3 = 0;
    reg blue_register3  = 0;
    reg red_register4   = 0;
    reg green_register4 = 0;
    reg blue_register4  = 0;

    reg [3:0] counter = 1;
    // Register Inicio de maquina
    reg [2:0] state = S_UPDATE_DATA_ROW ;

    // Data RGB
    reg [35:0] pixels_to_shift=0;
    reg [3:0] dataPixelR=0;
    reg [3:0] dataPixelG=0;
    reg [3:0] dataPixelB=0;

    reg [3:0] dataPixelR2=0;
    reg [3:0] dataPixelG2=0;
    reg [3:0] dataPixelB2=0;

    reg [3:0] dataPixelR3=0;
    reg [3:0] dataPixelG3=0;
    reg [3:0] dataPixelB3=0;

    reg [3:0] dataPixelR4=0;
    reg [3:0] dataPixelG4=0;
    reg [3:0] dataPixelB4=0;

    reg [30:0] count3;
    reg cleanColumns=1;

    //asginacion de las señales RGB de salida
    assign o_data_r = data_r;
    assign o_data_g = data_g;
    assign o_data_b = data_b;

    assign o_data_r2 = data_r2;
    assign o_data_g2 = data_g2;
    assign o_data_b2 = data_b2;

    //asginacion de la señal de seleccion de salida
    assign o_row_select = w_o_row_select;

    //asignacion de la data RGB segun la ram seleccionada 
    assign data = (data1*ram1Select) | (data2*ram2Select);
//---------------------------------------------------------------------------------------------------

//-------------------------------------Memorias Ram de doble puerto----------------------------------
    // Instanciación RAM 1
    ram #(.IMAGEN("imagen1.txt")) Ram1
            (.i_clk      (i_clk),

            .rd         (ram1Select),
            .addrRead   (addrRead),
            .o_valor    (data1),

            //.wr         (~ram1Select),
            .wr         (wr),
            .addrWrite  (addrWrite),
            .dataLine   (dataLine1)
            );

    // Instanciación RAM 2
    ram #(.IMAGEN("imagen2.txt")) Ram2
            (.i_clk      (i_clk),

            .rd         (ram2Select),
            .addrRead   (addrRead),
            .o_valor    (data2),

            //.wr         (~ram2Select),
            .wr         (~wr),
            .addrWrite  (addrWrite),
            .dataLine   (dataLine2)
            );
//---------------------------------------------------------------------------------------------------

//-------------------------------------Conmutacion de memorias---------------------------------------
always @(posedge i_clk) begin        
        if (ramSelectCounter == 0) begin
            ramSelectCounter <= RamTime;
            ram1Select <= ram2Select;
            ram2Select <= ~ram2Select;
            //requireData <= 1;
            requireData <= ~requireData;
            led <= ~led;
        end else begin
            ramSelectCounter <= ramSelectCounter - 1;
            //requireData <= 0;
        end
    end
//--------------------------------------------------------------------------------------------------
   
    
//--------------------------------Maquina de estados------------------------------------------------
    always @(posedge i_clk) begin
        case (state)
        S_UPDATE_DATA_ROW : begin
        //--------------------------------Module UpdateDataRow----------------------------
            enable_ram=1;
            addrRead = pixels_to_shift + 160*(w_o_row_select + 1)*cleanColumns;

            dataPixelR=data[17:15];
            dataPixelG=data[14:12];
            dataPixelB=data[11:9];

            dataPixelR2=data[8:6];
            dataPixelG2=data[5:3];
            dataPixelB2=data[2:0];

            dataPixelR3=data[35:33];
            dataPixelG3=data[32:30];
            dataPixelB3=data[29:27];

            dataPixelR4=data[26:24];
            dataPixelG4=data[23:21];
            dataPixelB4=data[20:18];

            if (pixels_to_shift != pixels_per_row ) begin
                if (o_data_clock == 1) begin

                    red_register    = (counter<=dataPixelR) ? 1'b1 : 1'b0; 
                    red_register2   = (counter<=dataPixelR2) ? 1'b1 : 1'b0; 
                    green_register  = (counter<=dataPixelG) ? 1'b1 : 1'b0; 
                    green_register2 = (counter<=dataPixelG2) ? 1'b1 : 1'b0; 
                    blue_register   = (counter<=dataPixelB) ? 1'b1 : 1'b0; 
                    blue_register2  = (counter<=dataPixelB2) ? 1'b1 : 1'b0; 
                    
                    red_register3   = (counter<=dataPixelR3) ? 1'b1 : 1'b0; 
                    red_register4   = (counter<=dataPixelR4) ? 1'b1 : 1'b0; 
                    green_register3  = (counter<=dataPixelG3) ? 1'b1 : 1'b0; 
                    green_register4 = (counter<=dataPixelG4) ? 1'b1 : 1'b0; 
                    blue_register3   = (counter<=dataPixelB3) ? 1'b1 : 1'b0; 
                    blue_register4  = (counter<=dataPixelB4) ? 1'b1 : 1'b0;

                    data_r <= { red_register2, red_register}; 
                    data_g <= { green_register2, green_register}; 
                    data_b <= { blue_register2, blue_register}; 

                    data_r2 <= { red_register4, red_register3}; 
                    data_g2 <= { green_register4, green_register3}; 
                    data_b2 <= { blue_register4, blue_register3}; 

                    o_data_clock <= 0;
                end else begin
                    o_data_clock <= 1;
                    pixels_to_shift <= pixels_to_shift + 1;
                end
            end else
               state <= S_BLANK_SET;
        //--------------------------------------------------------------------------------
         end

         S_BLANK_SET: begin 
            enable_ram<=0; 
            o_data_blank <= 1; 
            state <= S_LATCH_SET; 
         end
         
         S_LATCH_SET: begin     
            o_data_latch <= 1; 
            state <= S_INCREMENT_ROW; end
         
         S_INCREMENT_ROW: begin 
        //------------------------------Module Rows---------------------------------------  
            if(w_o_row_select==19)begin
                w_o_row_select<=0;
            end
            else begin
                w_o_row_select <=w_o_row_select + 1;
            end
        //--------------------------------------------------------------------------------
            state <= S_LATCH_CLEAR; 
        end

         S_LATCH_CLEAR: begin 
            o_data_latch <= 0; 
            state <= S_BLANK_CLEAR; 
            end

         S_BLANK_CLEAR: begin
            o_data_blank <= 0;
            pixels_to_shift <= 0;
            state <= S_INCREMENT_PWM;
            if (w_o_row_select == 19) begin
                state <= S_INCREMENT_PWM;
            end
            else begin
                cleanColumns=1;
                state <= S_UPDATE_DATA_ROW ; 
            end
         end

         S_INCREMENT_PWM: begin   
        //--------------------------------------Module Counter_PWM---------------------------------------   
            cleanColumns=0;
            if (counter == 7)
                counter <= 1;
            else
                counter <= counter + 1;
            state <= S_UPDATE_DATA_ROW ; 
        //--------------------------------------------------------------------------------
         end
        endcase 
    end
endmodule
//---------------------------------------------------------------------------------------------------
