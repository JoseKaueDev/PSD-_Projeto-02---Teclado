package teclado_pkg;
  typedef struct packed {
    logic [19:0][3:0] digits;   // digits[0] = último dígito
  } digitosPac_t;
endpackage
 
import teclado_pkg::*;

module decodificador_de_teclado (
  input  logic        clk,          // 1 kHz
  input  logic        rst,          // assíncrono, ativo em 1
  input  logic        enable,       // subida habilita, descida desabilita
  input  logic [3:0]  col_matriz,   // 0 = tecla pressionada
  output logic [3:0]  lin_matriz,   // ativa em 0, uma linha por ciclo
  output digitosPac_t digitos_value,
  output logic        digitos_valid // pulso de 1 ciclo quandso confirm, especial, timeout após
); 

  logic [31:0]cont_debounce; 
  logic [31:0] time_out; 
  logic [31:0] tempA ;
  logic [31:0]cont_debounce_A; 
  logic [31:0] temp; 
  logic [31:0] cont_press; 

//são flags, apenas 1 bit
  logic tem_num; 
  logic A_solto;
  logic buffer; 
  
  
  
     enum logic [4:0] {IDLE, VARREDURA, DEBOUNCE, OPERADOR, FUNCAO_NUM, AGUARDA, PRESSIONANDO, FUNCAO_A,
     VARREDURA_A, DEBOUNCE_A, FUNCAO_A_NUM, AGUARDA_SOLTURA_A_NUM, ENVIA_A_NUM, FUNCAO_SO_A,
     FUNCAO_ESPECIAL, AGUARDA_ESPECIAL, VARREDURA_ESPECIAL, PROCESSO_DE_CONFIRMACAO, LIMPEZA, AGUARDANDO, TIMEOUT, DEFAULT} ESTADO;
  
  logic [7:0] estado_teclado;
  logic [3:0] tecla_atual;

  assign estado_teclado = {lin_matriz, col_matriz};

  always_comb begin
      
      case (estado_teclado)
          8'b1110_1011: tecla_atual = 4'h0; // Tecla 0
          8'b0111_0111: tecla_atual = 4'h1; // Tecla 1
          8'b0111_1011: tecla_atual = 4'h2; // Tecla 2
          8'b0111_1101: tecla_atual = 4'h3; // Tecla 3
          8'b1011_0111: tecla_atual = 4'h4; // Tecla 4
          8'b1011_1011: tecla_atual = 4'h5; // Tecla 5
          8'b1011_1101: tecla_atual = 4'h6; // Tecla 6
          8'b1101_0111: tecla_atual = 4'h7; // Tecla 7
          8'b1101_1011: tecla_atual = 4'h8; // Tecla 8
          8'b1101_1101: tecla_atual = 4'h9; // Tecla 9
          8'b0111_1110: tecla_atual = 4'hA; // Tecla A
          8'b1011_1110: tecla_atual = 4'hB; // Tecla B
          8'b1101_1110: tecla_atual = 4'hC; // Tecla C
          8'b1110_1110: tecla_atual = 4'hD; // Tecla D
          8'b1110_0111: tecla_atual = 4'hE; // Tecla *
          8'b1110_1101: tecla_atual = 4'hF; // Tecla #
          default: begin
              tecla_atual = 4'h0;
          end
      endcase
  end
    
    always_ff @ (posedge clk or posedge rst) begin

      if(rst) begin
        ESTADO <= IDLE;
        time_out      <= 0;
        cont_debounce <= 0;
        cont_press    <= 0;
        buffer        <= 0;
        digitos_value <= '1;
      end

      else begin
        case(ESTADO)
            IDLE: begin
                temp <= 0;
                time_out <= 0;
                cont_debounce <= 0;
                cont_debounce_A <= 0;
                ESTADO <= VARREDURA;
            end
          
            VARREDURA: begin
                time_out <= time_out +1;
                if(time_out < 5000 && col_matriz == 4'b1111) 
                    ESTADO <= VARREDURA;
                else if(col_matriz != 4'b1111) 
                    ESTADO <= DEBOUNCE;
                else if(time_out >= 5000 && buffer == 0)
                    ESTADO <= TIMEOUT;
            end

            DEBOUNCE: begin
                cont_debounce <= cont_debounce + 1;
                if(cont_debounce < 100)
                    ESTADO <= DEBOUNCE;
                else if(col_matriz == 4'b1111)
                    ESTADO <= VARREDURA;
                else 
                    ESTADO <= OPERADOR;
            end 

            OPERADOR: begin
                if (tecla_atual >= 4'h0 && tecla_atual <= 4'h9) 
                    ESTADO <= FUNCAO_NUM;
                else if(tecla_atual == 4'hA)
                    ESTADO <= FUNCAO_A;
                else if (tecla_atual >= 4'hB && tecla_atual <= 4'hD || tecla_atual == 0'hF)
                    ESTADO <= FUNCAO_ESPECIAL;
                else //*
                    ESTADO <= PROCESSO_DE_CONFIRMACAO;
            end

            FUNCAO_NUM: begin
                ESTADO <= AGUARDA;
                buffer <= 1;
            end

            AGUARDA: begin
                cont_press <= cont_press + 1;
                if (col_matriz != 4'b1111 && cont_press < 2000)
                    ESTADO <= AGUARDA;
                else if (col_matriz != 4'b1111 && cont_press >= 2000)
                    ESTADO <= PRESSIONANDO;
                else
                    ESTADO <= VARREDURA;
            end

            FUNCAO_A: begin
                tempA <= 0;
                //dar um jeito de guardar A, pois Não podemos configulá-lo em alwais ff e comb ao mesmo tempo. podemos criar 
                ESTADO <= VARREDURA_A;
            end

            VARREDURA_A: begin
                tempA <= tempA + 1;
                if (tecla_atual == 4'hA && col_matriz == 4'b1111)
                    ESTADO <= VARREDURA_A;
                else if (A_solto == 1 && temp_A < 5000 && tem_num == 0)
                    ESTADO <= VARREDURA_A;
                else if (A_solto == 0 && temp_A >= 5000 && tem_num == 0)
                    ESTADO <= FUNCAO_SO_A;
                else if (tecla_atual >= 4'h0 && tecla_atual <= 4'h9 && A_solto == 0)
                    ESTADO <= DEBOUNCE_A;
                else
                    ESTADO <= ENVIA_A_NUM;
            end

            DEBOUNCE_A: begin
                cont_debounce_A <= cont_debounce_A + 1;
                if(cont_debounce_A < 100)
                    ESTADO <= DEBOUNCE_A;
                else
                    ESTADO <= FUNCAO_A_NUM;
            end

            FUNCAO_A_NUM: 
                ESTADO <= AGUARDA_SOLTURA_A_NUM;

            AGUARDA_SOLTURA_A_NUM: begin
                count_debounce_A <= count_debounce_A + 1;
                if(A_solto == 0 && num_solto == 1) 
                    ESTADO <= VARREDURA_A;
                else if(num_solto == 0 || (A_solto == 1 && num_solto == 1 && count_debounce_A < 100))
                    ESTADO <= AGUARDA_SOLTURA_A_NUM;
                else if(A_solto == 1 && num_solto == 1 && count_debounce_A >= 100)
                    ESTADO <= ENVIA_A_NUM;
            end

            ENVIA_A_NUM:
                ESTADO <= LIMPEZA;
            
            FUNCAO_SO_A:
                ESTADO <= LIMPEZA;
            
            FUNCAO_ESPECIAL:
                ESTADO <= AGUARDA_ESPECIAL; 
         
            AGUARDA_ESPECIAL: begin
                temp <= temp + 1;
                if (temp > 100 && temp <= 5000)
                    ESTADO <= AGUARDA_ESPECIAL;
                else if ((tecla_atual != 4'hB && tecla_atual != 4'hC && tecla_atual != 4'hD && tecla_atual != 4'hF) && temp >= 5000)
                    ESTADO <= VARREDURA_ESPECIAL;
                else
                    ESTADO <= VARREDURA;
            end

            VARREDURA_ESPECIAL:
                ESTADO <= LIMPEZA;


            PROCESSO_DE_CONFIRMACAO:
                ESTADO <= LIMPEZA;
            
            LIMPEZA:
                ESTADO <= AGUARDANDO;

            AGUARDANDO: begin
                if(col_matriz != 4'b1111)
                    ESTADO <= AGUARDANDO;
                else
                    ESTADO <= VARREDURA;
            end

            TIMEOUT:
                ESTADO <= LIMPEZA;   

        endcase
        end


endmodule