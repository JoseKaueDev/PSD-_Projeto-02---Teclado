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

  logic [31:0] cont_debounce; 
  logic [31:0] time_out; 
  logic [31:0] temp_A;
  logic [31:0] cont_debounce_A; 
  logic [31:0] temp; 
  logic [31:0] cont_press; 

//são flags, apenas 1 bit
  logic tem_num; 
  logic A_solto;
  logic buffer;
  logic num_solto;

  logic tecla_valida;   // 1 = existe tecla apertada, 0 = nenhuma tecla
  
  
     enum logic [4:0] {IDLE, VARREDURA, DEBOUNCE, OPERADOR, FUNCAO_NUM, AGUARDA, PRESSIONANDO, FUNCAO_A,
     VARREDURA_A, DEBOUNCE_A, FUNCAO_A_NUM, AGUARDA_SOLTURA_A_NUM, ENVIA_A_NUM, FUNCAO_SO_A,
     FUNCAO_ESPECIAL, AGUARDA_ESPECIAL, VARREDURA_ESPECIAL, PROCESSO_DE_CONFIRMACAO, LIMPEZA, AGUARDANDO, TIMEOUT, DEFAULT} ESTADO, PROX_ESTADO;
  
// variaveis do sincronizador 
  logic [3:0] col_ff1, col_sync, lin_d1, lin_d2;
 
  logic [3:0] tecla_atual;

//para varredura do lin_matriz
  logic [3:0] prox_lin; 

logic [3:0] tecla_salva;
logic [3:0] linha_salva;
logic [3:0] col_salva;

//Guilherme pediu
  logic[3:0] num_salvo;  
  logic [3:0] linha_num_A;
  logic [3:0]  col_num_A; 
  logic [31:0] cont_soltura_A; 
  logic [31:0] cont_soltura_num;
  logic num_invalido_esp;

//verifica na linha 0111 se a coluna da tecla A subiu para 1 
  logic pino_A_solto;
  assign pino_A_solto = (lin_d2 == 4'b0111) && (col_sync[0] == 1'b1);

//verifica se a linha do numero A + n e o bit da coluna dele subiu para 1
  logic pino_num_A_solto;
  assign pino_num_A_solto = (lin_d2 == linha_num_A) && ((col_sync & col_num_A) != 4'b0000);




    //varredura linha
    always_comb begin
        case(lin_matriz)
            4'b0111: prox_lin = 4'b1011;
            4'b1011: prox_lin = 4'b1101;
            4'b1101: prox_lin = 4'b1110;
            default: prox_lin = 4'b0111;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) lin_matriz <= 4'b1111;
        else    lin_matriz <= prox_lin;
    end

    //sincronizador + atraso da linha
    always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    col_ff1 <= 4'b1111;
    col_sync <= 4'b1111;
    lin_d1 <= 4'b1111;
    lin_d2 <= 4'b1111;
  end else begin

    col_ff1 <= col_matriz;
    col_sync <= col_ff1;
    
    lin_d1 <= lin_matriz;
    lin_d2 <= lin_d1;

  end
end

//modificacao no case para que tenha prioridade na coluna 3 ate a coluna 0 (bit mais alto para o bit mais baixo)
// esse case com o ? está certo.
 always_comb begin
      tecla_atual  = 4'h0;     // valores padrão (evitam latch)
      tecla_valida = 1'b0;
 
       casez ({lin_d2, col_sync})
          // Linha 1 (0111): 1, 2, 3, A
          8'b0111_0???: begin tecla_atual = 4'h1; tecla_valida = 1'b1; end // Tecla 1 (col[3]=0)
          8'b0111_10??: begin tecla_atual = 4'h2; tecla_valida = 1'b1; end // Tecla 2 (col[2]=0)
          8'b0111_110?: begin tecla_atual = 4'h3; tecla_valida = 1'b1; end // Tecla 3 (col[1]=0)
          8'b0111_1110: begin tecla_atual = 4'hA; tecla_valida = 1'b1; end // Tecla A (col[0]=0)
          // Linha 2 (1011): 4, 5, 6, B
          8'b1011_0???: begin tecla_atual = 4'h4; tecla_valida = 1'b1; end // Tecla 4
          8'b1011_10??: begin tecla_atual = 4'h5; tecla_valida = 1'b1; end // Tecla 5
          8'b1011_110?: begin tecla_atual = 4'h6; tecla_valida = 1'b1; end // Tecla 6
          8'b1011_1110: begin tecla_atual = 4'hB; tecla_valida = 1'b1; end // Tecla B
          // Linha 3 (1101): 7, 8, 9, C
          8'b1101_0???: begin tecla_atual = 4'h7; tecla_valida = 1'b1; end // Tecla 7
          8'b1101_10??: begin tecla_atual = 4'h8; tecla_valida = 1'b1; end // Tecla 8
          8'b1101_110?: begin tecla_atual = 4'h9; tecla_valida = 1'b1; end // Tecla 9
          8'b1101_1110: begin tecla_atual = 4'hC; tecla_valida = 1'b1; end // Tecla C
          // Linha 4 (1110): *, 0, #, D
          8'b1110_0???: begin tecla_atual = 4'hE; tecla_valida = 1'b1; end // Tecla *
          8'b1110_10??: begin tecla_atual = 4'h0; tecla_valida = 1'b1; end // Tecla 0
          8'b1110_110?: begin tecla_atual = 4'hF; tecla_valida = 1'b1; end // Tecla #
          8'b1110_1110: begin tecla_atual = 4'hD; tecla_valida = 1'b1; end // Tecla D
          default:      begin tecla_atual = 4'h0; tecla_valida = 1'b0; end // nenhuma tecla
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
                if (tecla_valida) begin
                    tecla_salva   <= tecla_atual; // Memoriza qual tecla foi apertada
                    linha_salva   <= lin_d2;      // Memoriza a linha da tecla
                    col_salva     <= col_sync;    // Memoriza a coluna da tecla
                    time_out      <= 0;  
                    cont_debounce <= 1;           // Inicia a contagem de 100 ciclos (T0i)
                    ESTADO        <= DEBOUNCE;
                end 
                else if (buffer == 1'b1) begin
                    if (time_out >= 4999) begin
                        ESTADO   <= TIMEOUT;
                    end else begin
                        time_out <= time_out + 1;
                        ESTADO   <= VARREDURA;
                    end
                end 
                else begin
                    time_out <= 0;
                    ESTADO   <= VARREDURA;
                end
            end

            DEBOUNCE: begin
                // Se está na linha da tecla e a tecla sumiu (quique/ruído), descarta T0i e volta
                if (lin_d2 == linha_salva && (col_sync & ~col_salva) != 4'b0000) begin
                    cont_debounce <= 0;
                    ESTADO <= VARREDURA;
                end else if (cont_debounce < 99) begin
                    cont_debounce <= cont_debounce + 1;
                    ESTADO <= DEBOUNCE;
                end else begin
                    cont_debounce <= 0;
                    ESTADO <= OPERADOR;
                end
            end 

            OPERADOR: begin
                if (tecla_salva >= 4'h0 && tecla_salva <= 4'h9) 
                    ESTADO <= FUNCAO_NUM;
                else if(tecla_salva == 4'hA)
                    ESTADO <= FUNCAO_A;
                else if (tecla_salva >= 4'hB && tecla_salva <= 4'hD || tecla_salva == 4'hF)
                    ESTADO <= FUNCAO_ESPECIAL;
                else
                    ESTADO <= PROCESSO_DE_CONFIRMACAO;
            end

            FUNCAO_NUM: begin
                ESTADO <= AGUARDA;
                buffer <= 1;
            end

            AGUARDA: begin
                // --- Acompanhamento da Soltura (100 ciclos) ---
                if (cont_soltura == 0) begin
                    if (tecla_salva_solta) cont_soltura <= 1; // Início da soltura (T0f)
                end else begin
                    if (lin_d2 == linha_salva && !tecla_salva_solta)
                        cont_soltura <= 0; // Reapareceu antes de 100 ciclos: cancela T0f!
                    else
                        cont_soltura <= cont_soltura + 1;
                end

                // --- Transições e Auto-repetição (2000 ciclos) ---
                if (cont_soltura >= 99) begin
                    // Soltura confirmada (T0f + 100): volta para varredura e inicia timeout
                    cont_soltura <= 0;
                    cont_press   <= 0;
                    time_out     <= 0;
                    ESTADO       <= VARREDURA;
                end else if (cont_press >= 1999) begin
                    // 2000 ciclos pressionada: 1ª auto-repetição!
                    digitos_value.digits <= {digitos_value.digits[18:0], tecla_salva};
                    cont_press           <= 0;
                    ESTADO               <= PRESSIONANDO;
                end else begin
                    cont_press <= cont_press + 1;
                    ESTADO     <= AGUARDA;
                end
            end

            PRESSIONANDO: begin
                // --- Acompanhamento da Soltura (100 ciclos) ---
                if (cont_soltura == 0) begin
                    if (tecla_salva_solta) cont_soltura <= 1;
                end else begin
                    if (lin_d2 == linha_salva && !tecla_salva_solta)
                        cont_soltura <= 0; // Quique na soltura: cancela T0f
                    else
                        cont_soltura <= cont_soltura + 1;
                end

                // --- Transições e Auto-repetições seguintes (1000 ciclos) ---
                if (cont_soltura >= 99) begin
                    cont_soltura <= 0;
                    cont_press   <= 0;
                    time_out     <= 0;
                    ESTADO       <= VARREDURA;
                end else if (cont_press >= 999) begin
                    // +1000 ciclos pressionada: repete o dígito!
                    digitos_value.digits <= {digitos_value.digits[18:0], tecla_salva};
                    cont_press           <= 0;
                    ESTADO               <= PRESSIONANDO;
                end else begin
                    cont_press <= cont_press + 1;
                    ESTADO     <= PRESSIONANDO;
                end
            end


            //modificacao do funcao A
            FUNCAO_A: begin
                temp_A <= 100;
                tem_num <= 1'b0;
                A_solto <= 1'b0;
                num_solto <= 1'b1;
                cont_soltura_A <= 0;
                cont_soltura_num <= 0;
                ESTADO <= VARREDURA_A;
            end

            //varredura a acompanha se a tecla A foi solta e depois a transicao para onde ir
            VARREDURA_A: begin
                //  1. Acompanha se a tecla A foi solta (debounce de 100 ciclos) 
                if (!A_solto) begin
                    if (cont_soltura_A == 0) begin
                        temp_A <= temp_A + 1;
                        if (pino_A_solto) cont_soltura_A <= 1;
                    end else begin
                        if (lin_d2 == 4'b0111 && !pino_A_solto) begin
                            cont_soltura_A <= 0; // quique de A cancela T0f
                            temp_A         <= temp_A + cont_soltura_A + 1;
                        end else if (cont_soltura_A >= 99) begin
                            A_solto        <= 1'b1; // soltura de A confirmada
                        end else begin
                            cont_soltura_A <= cont_soltura_A + 1;
                        end
                    end
                end
 
                // 2. decisoes de transicao de VARREDURA_A 
                if (A_solto) begin
                    // A já soltou completamente
                    if (tem_num) begin
                        ESTADO <= ENVIA_A_NUM; // Tinha numero confirmado antes e agora soltou A
                    end else if (temp_A >= 5000) begin
                        ESTADO <= FUNCAO_SO_A; // Sa A por >= 5000 ciclos
                    end else begin
                        time_out <= 0;         // So A por < 5000 ciclos: ignorada, volta à varredura
                        ESTADO   <= VARREDURA;
                    end
                end else if (tecla_valida && tecla_atual <= 4'h9 && cont_soltura_A == 0) begin
                    // Detectou um numero (0 a 9) enquanto A esta pressionado
                    num_salvo       <= tecla_atual; // Usa provisoriamente ou salva alvo do debounce
                    linha_num_A     <= lin_d2;
                    // Cria mascara apenas para o bit da coluna desse número:
                    col_num_A       <= (tecla_atual == 4'h1 || tecla_atual == 4'h4 || tecla_atual == 4'h7) ? 4'b1000 :
                                       (tecla_atual == 4'h2 || tecla_atual == 4'h5 || tecla_atual == 4'h8 || tecla_atual == 4'h0) ? 4'b0100 :
                                       4'b0010; // colunas de 3, 6, 9
                    cont_debounce_A <= 1;
                    ESTADO          <= DEBOUNCE_A;
                end else begin
                    ESTADO <= VARREDURA_A;
                end
            end

            DEBOUNCE_A: begin
                // Ainda verifica o A
                if (!A_solto) begin
                    if (cont_soltura_A == 0) begin
                        temp_A <= temp_A + 1;
                        if (pino_A_solto) cont_soltura_A <= 1;
                    end else begin
                        if (lin_d2 == 4'b0111 && !pino_A_solto) begin
                            cont_soltura_A <= 0;
                            temp_A         <= temp_A + cont_soltura_A + 1;
                        end else if (cont_soltura_A >= 99) begin
                            A_solto <= 1'b1;
                        end else begin
                            cont_soltura_A <= cont_soltura_A + 1;
                        end
                    end
                end
 
                // verifica se o numero saiu antes dos 100 ciclos do debounce
                if (pino_num_A_solto) begin
                    cont_debounce_A <= 0;
                    ESTADO          <= VARREDURA_A; // ruido no numero: volta para varredura_A
                end else if (cont_debounce_A < 99) begin  //continua no debounce_A
                    cont_debounce_A <= cont_debounce_A + 1;
                    ESTADO          <= DEBOUNCE_A;
                end else begin  //vai para funcao A num
                    cont_debounce_A <= 0;
                    ESTADO          <= FUNCAO_A_NUM;
                end
            end

            FUNCAO_A_NUM: begin
                tem_num <= 1'b1;  // confirma que pelomenos tem um numero
                num_solto <= 1'b0;
                cont_soltura_num <= 0;
                ESTADO <= AGUARDA_SOLTURA_A_NUM;
            end

            AGUARDA_SOLTURA_A_NUM: begin
                //verifica a soltura do A nos 100 ciclos
                if(!A_solto) begin
                    if(cont_soltura_A == 0) begin
                        if(pino_A_solto) cont_soltura_A <= 1;
                    end else begin
                        if(lin_d2 ==4'b0111 && !pino_A_solto)
                            cont_soltura_A <= 0;
                        else if(cont_soltura_A >= 99)
                        A_solto <= 1'b1;
                        else
                        cont_soltura_A <= cont_soltura_A +1;
                    end
                end
                //Verifica a soltura do numero em 100 ciclos
                if(!num_solto) begin
                    if(cont_soltura_num == 0) begin
                        if(pino_num_A_solto) cont_soltura_num <= 1;
                    end else begin
                        if(lin_d2 == linha_num_A && !pino_num_A_solto)
                        cont_soltura_num <= 0;
                    else if(cont_soltura_num >= 99)
                        num_solto <= 1'b1;
                    else
                        cont_soltura_num <= cont_soltura_num + 1;
                    end
                end
                //transicao da saida
                if(A_solto && num_solto) begin
                    ESTADO <= ENVIA_A_NUM; //tudo foi solto e confirmado
                end else if(!A_solto && num_solto) begin
                    ESTADO <= VARREDURA_A;  //soltou o numero mas A pressionado ainda
                end else begin
                    ESTADO <= AGUARDA_SOLTURA_A_NUM;
                end
            end

            ENVIA_A_NUM:begin
                digitos_value.digits <= { {18{4'hF}}, 4'hA, num_salvo }; // F...FAn
                digitos_valid        <= 1'b1;
                cont_soltura         <= 100; // ambos ja estao soltos
                ESTADO               <= LIMPEZA;
            end
            FUNCAO_SO_A:
                ESTADO <= LIMPEZA;
            
            FUNCAO_ESPECIAL:begin
                digitos_value.digits <= { {19{4'hF}}, 4'hA }; // F...FA
                digitos_valid        <= 1'b1;
                cont_soltura         <= 100; // A ja esta solto
                ESTADO  
            end

            
            AGUARDA_ESPECIAL: begin
                temp <= temp + 1;
                if (temp > 100 && temp <= 5000)
                    ESTADO <= AGUARDA_ESPECIAL;
                else if ((tecla_salva != 4'hB && tecla_salva != 4'hC && tecla_salva != 4'hD && tecla_salva != 4'hF) && temp >= 5000)
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
                if(col_sync != 4'b1111)
                    ESTADO <= AGUARDANDO;
                else
                    ESTADO <= VARREDURA;
            end

            TIMEOUT:
                ESTADO <= LIMPEZA;   
    
        endcase
      end
        end


endmodule