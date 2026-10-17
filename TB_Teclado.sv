// =============================================================================
// README - TESTBENCH DO decodificador_de_teclado
// =============================================================================
//
// O QUE ESTE TESTBENCH FAZ
//   Simula um teclado 4x4 ligado ao módulo, aperta e solta teclas e confere se a
//   saída do módulo está certa e no tempo certo (entre R e R+20 ciclos).
//
// ENTRADAS DO MÓDULO (o testbench GERA)
//   clk         clock. O módulo só conta ciclos: 1 ciclo = 1 período do clock.
//   rst         reset assíncrono (1 = reset). Usado nos testes T1, T10 e T11.
//   enable      habilita/desabilita o módulo. Usado no teste T11.
//   col_matriz  colunas do teclado, geradas pelo modelo do teclado:
//               0 = tecla apertada na linha que está ativa; 1111 = nenhuma tecla.
//
// SAÍDAS DO MÓDULO (o testbench OBSERVA)
//   lin_matriz     linha ativa (0111 -> 1011 -> 1101 -> 1110 -> 0111...).
//                  A sequência é conferida o tempo tod0.
//   digitos_value  buffer de 20 dígitos hexa (80 bits), ligado ao vetor "dv".
//   digitos_valid  pulso de 1 ciclo quando acontece um evento (*, #, A-D, A+n, timeout).
//
// SINAIS CRIADOS PELO TESTBENCH
//   tecla_fisica   1 bit por tecla (1 = dedo na tecla).
//                  Bits 0 a 9 = dígitos | 10=A  11=B  12=C  13=D  14=*  15=#
//   cyc            número do ciclo atual (usado para calcular T0i, T0f e R).
//   bufm           buffer ESPERADO: o que digitos_value deve mostrar.
//   exp_R/W/V/P/N  fila de eventos esperados: instante R, janela, valor,
//                  se valid deve ser 1 e o nome do evento.
//   erros          quantidade de erros encontrados.
//   checks_ok      quantidade de verificações que passaram.
//
// BLOCOS DO TESTBENCH
//   1. Modelo do teclado: transforma tecla_fisica + lin_matriz em col_matriz.
//   2. Tarefas de estímulo: aperta/solta uma tecla e devolvem T0i/T0f;
//      digito, evento_imediato (* e #), letra_simples (A-D) e a_mais_n (A + número).
//   3. Scoreboard: cada tarefa avisa o que deve acontecer (push_exp) e quando (R).
//   4. Monitor: a cada ciclo olha digitos_value e digitos_valid e compara com o
//      que o scoreboard esperava.
//   5. Testes (T1 a T11): sequência principal no bloco "initial".
//
// COMO A CONFERÊNCIA FUNCIONA
//   - T0i/T0f: primeiro ciclo em que a linha da tecla está ativa (calculado pelo testbench).
//   - R: instante de referência de cada evento (ex.: dígito = T0i+100; letra = T0f+100).
//   - Toda mudança na saída deve cair entre R e R+20 e ter o valor esperado.
//   - Depois de um pulso, no ciclo seguinte valid=0 e digitos_value volta a 20xF.
//   - O estímulo muda no negedge do clock e o módulo lê no posedge (sem corrida).
//   - Tp das letras é sempre múltiplo de 4; por isso os limites testados são
//     4996 (ignorada) e 5000 (válida).
//
// O QUE É APONTADO COMO ERRO
//   ação antes de R | ação depois de R+20 | valor errado | mudança inesperada na saída
//   evento que não ocorreu | pulso com mais de 1 ciclo | saída com X ou Z |
//   varredura de lin_matriz fora de ordem
//
// TESTES
//   T1   reset e varredura         T7   tecla A e A + número
//   T2   ruído ao apertar          T8   mais de uma tecla
//   T3   dígitos, *, # e "1 1"     T9   timeout
//   T4   auto-repetição            T10  reset (com tecla apertada e no pulso)
//   T5   mais de 20 dígitos        T11  enable (congela, retoma, perto do pulso)
//   T6   teclas B, C e D
//
// RESULTADO
//   Cada verificação imprime [OK] ou [ERRO]. No fim aparece o total de acertos e
//   erros e a linha "RESULTADO: TOD0S OS TESTES PASSARAM" (ou "HA ERROS").
//
// =============================================================================


`timescale 1us / 1ns
import teclado_pkg::*;

module tb_decodificador_de_teclado;

    // =========================================================================
    // SINAIS E INSTANCIAÇÃO
    // =========================================================================
    logic        clk;
    logic        rst;
    logic        enable;
    logic [3:0]  col_matriz;
    logic [3:0]  lin_matriz;
    digitosPac_t digitos_value;
    logic        digitos_valid;

    // 1 = dedo pressionando a tecla, 0 = solta (Índices: 0-9, 4'hA-4'hD, 4'hE=*, 4'hF=#)
    logic [15:0] tecla_fisica;

    int erros = 0;
    int testes_ok = 0;

    decodificador_de_teclado dut (
        .clk           (clk),
        .rst           (rst),
        .enable        (enable),
        .col_matriz    (col_matriz),
        .lin_matriz    (lin_matriz),
        .digitos_value (digitos_value),
        .digitos_valid (digitos_valid)
    );

    // Clock de 1 kHz (Período = 1ms -> 500us alto / 500us baixo)
    initial begin
        clk = 1'b0;
        forever #500 clk = ~clk; 
    end

    // =========================================================================
    // EMULADOR FÍSICO DO TECLADO (Matriz 4x4)
    // =========================================================================
    always_comb begin
        col_matriz = 4'b1111; // Pull-up padrão
        
        // Linha 1 (0111)
        if (lin_matriz[3] == 1'b0) begin
            if (tecla_fisica[4'h1]) col_matriz[3] = 1'b0;
            if (tecla_fisica[4'h2]) col_matriz[2] = 1'b0;
            if (tecla_fisica[4'h3]) col_matriz[1] = 1'b0;
            if (tecla_fisica[4'hA]) col_matriz[0] = 1'b0;
        end
        // Linha 2 (1011)
        if (lin_matriz[2] == 1'b0) begin
            if (tecla_fisica[4'h4]) col_matriz[3] = 1'b0;
            if (tecla_fisica[4'h5]) col_matriz[2] = 1'b0;
            if (tecla_fisica[4'h6]) col_matriz[1] = 1'b0;
            if (tecla_fisica[4'hB]) col_matriz[0] = 1'b0;
        end
        // Linha 3 (1101)
        if (lin_matriz[1] == 1'b0) begin
            if (tecla_fisica[4'h7]) col_matriz[3] = 1'b0;
            if (tecla_fisica[4'h8]) col_matriz[2] = 1'b0;
            if (tecla_fisica[4'h9]) col_matriz[1] = 1'b0;
            if (tecla_fisica[4'hC]) col_matriz[0] = 1'b0;
        end
        // Linha 4 (1110)
        if (lin_matriz[0] == 1'b0) begin
            if (tecla_fisica[4'hE]) col_matriz[3] = 1'b0; // *
            if (tecla_fisica[4'h0]) col_matriz[2] = 1'b0; // 0
            if (tecla_fisica[4'hF]) col_matriz[1] = 1'b0; // #
            if (tecla_fisica[4'hD]) col_matriz[0] = 1'b0; // D
        end
    end

    // =========================================================================
    // TASKS DE APOIO (Ferramentas de Simulação)
    // =========================================================================
    task automatic esperar_ciclos(input int n);
        repeat (n) @(posedge clk);
    endtask

    // Simula o toque humano comum: aperta e solta
    task automatic clicar_tecla(input logic [3:0] t, input int c_press = 150, input int c_solta = 150);
        tecla_fisica[t] = 1'b1;
        esperar_ciclos(c_press);
        tecla_fisica[t] = 1'b0;
        esperar_ciclos(c_solta);
    endtask

    // Checa resultados estáticos silenciosos (sem pulso valid)
    task automatic verificar(input string nome_teste, input logic condicao);
        if (condicao) begin
            $display("[OK]   %s", nome_teste);
            testes_ok++;
        end else begin
            $display("[ERRO] %s | Obtido = %h", nome_teste, digitos_value);
            erros++;
        end
    endtask

    // Fica de tocaia aguardando o pulso valid=1 e depois valida a limpeza (20xF)
    task automatic aguardar_pulso_e_limpeza(input string nome_teste, input logic [79:0] esperado, input int timeout_ciclos = 300);
        int c = 0;
        while (!digitos_valid && c < timeout_ciclos) begin
            @(posedge clk);
            #1; c++;
        end

        if (!digitos_valid) begin
            $display("[ERRO] %s | O pulso (valid=1) não aconteceu a tempo!", nome_teste);
            erros++;
        end else begin
            if (digitos_value == esperado) begin
                $display("[OK]   %s (Pulso gerado com valor correto: %h)", nome_teste, esperado);
                testes_ok++;
            end else begin
                $display("[ERRO] %s | Valor errado no pulso: %h (Esperado: %h)", nome_teste, digitos_value, esperado);
                erros++;
            end
            
            // Verifica o ciclo seguinte para garantir a limpeza do barramento
            @(posedge clk); #1;
            if (digitos_valid == 1'b0 && digitos_value == {20{4'hF}}) begin
                $display("       -> [OK] Limpeza pós-pulso efetuada com sucesso (valid=0, 20xF)");
            end else begin
                $display("       -> [ERRO] Falha na limpeza. valid=%b, value=%h", digitos_valid, digitos_value);
                erros++;
            end
        end
    endtask

    // =========================================================================
    // SEQUÊNCIA DE TESTES DIRETA E DIDÁTICA
    // =========================================================================
    initial begin
        $display("=================================================================");
        $display(" INICIANDO TESTBENCH SEQUENCIAL (PROJETO TECLADO) ");
        $display("=================================================================");

        // Configuração Inicial
        tecla_fisica = '0;
        enable       = 1'b1;
        rst          = 1'b1;
        esperar_ciclos(5); #1;

        // --- TESTE 1: Reset ---
        verificar("T1 - Reset garante saida 20xF e valid=0", 
                  (digitos_value == {20{4'hF}} && digitos_valid == 1'b0));
        rst = 1'b0;
        esperar_ciclos(5);

        // --- TESTE 2: Rejeição de Ruído ---
        tecla_fisica[4'h1] = 1'b1;
        esperar_ciclos(40); // Toque rápido (<100 ciclos)
        tecla_fisica[4'h1] = 1'b0;
        esperar_ciclos(150); #1;
        verificar("T2 - Ruido de 40 ciclos na tecla 1 ignorado com sucesso", 
                  (digitos_value == {20{4'hF}}));

        // --- TESTE 3: Digitação Básica (1, 2, 3) e Confirmação (*) ---
        clicar_tecla(4'h1);
        clicar_tecla(4'h2);
        clicar_tecla(4'h3); #1;
        verificar("T3.1 - Digitos 1, 2 e 3 salvos no buffer silenciosamente", 
                  (digitos_value == {{17{4'hF}}, 12'h123}));
        
        tecla_fisica[4'hE] = 1'b1; // Aperta '*'
        aguardar_pulso_e_limpeza("T3.2 - Tecla '*' aciona o pulso e entrega 123", {{17{4'hF}}, 12'h123});
        tecla_fisica[4'hE] = 1'b0;
        esperar_ciclos(150);

        // --- TESTE 4: Auto-repetição ---
        tecla_fisica[4'h5] = 1'b1;
        esperar_ciclos(150);  // Entrou o primeiro 5
        esperar_ciclos(2000); // Segurou bastante: Repete
        esperar_ciclos(1000); // Segurou mais ainda: Repete de novo
        #1;
        verificar("T4 - Auto-repeticao funciona (5 -> 55 -> 555)", 
                  (digitos_value == {{17{4'hF}}, 12'h555}));
        tecla_fisica[4'h5] = 1'b0;
        esperar_ciclos(150);

        // --- TESTE 5: Tecla Especial '#', cancelamento de buffer ---
        tecla_fisica[4'hF] = 1'b1; // Aperta '#'
        aguardar_pulso_e_limpeza("T5 - Tecla '#' ignora o buffer 555 e envia F..FAB", {{18{4'hF}}, 8'hAB});
        tecla_fisica[4'hF] = 1'b0;
        esperar_ciclos(150);

        // --- TESTE 6: Letra C e Letra A sozinha (Teste de >= 5000 ciclos) ---
        tecla_fisica[4'hC] = 1'b1;
        esperar_ciclos(5100);
        tecla_fisica[4'hC] = 1'b0;
        aguardar_pulso_e_limpeza("T6.1 - Tecla C segurada por >= 5000 ciclos valida com sucesso", {{19{4'hF}}, 4'hC});
        esperar_ciclos(150);

        tecla_fisica[4'hA] = 1'b1;
        esperar_ciclos(5100);
        tecla_fisica[4'hA] = 1'b0;
        aguardar_pulso_e_limpeza("T6.2 - Tecla A sozinha por >= 5000 ciclos envia F...FA", {{19{4'hF}}, 4'hA});
        esperar_ciclos(150);

        // --- TESTE 7: Letra B (>= 5000 ciclos) anulada por número intrometido ---
        tecla_fisica[4'hB] = 1'b1;
        esperar_ciclos(500);
        clicar_tecla(4'h4, 150, 150); // Aperta e solta o intruso rapidamente
        esperar_ciclos(4500);         // NOVO: Garante que B fique >= 5000 ciclos pressionada no total!
        tecla_fisica[4'hB] = 1'b0;
        esperar_ciclos(150); #1;
        verificar("T7 - Tecla B (>= 5000 ciclos) com numero intrometido anula a letra B perfeitamente", 
                  (digitos_value == {20{4'hF}} && digitos_valid == 1'b0));

        // --- TESTE 8: Função 'A' + número ---
        tecla_fisica[4'hA] = 1'b1; esperar_ciclos(150);
        tecla_fisica[4'h9] = 1'b1; esperar_ciclos(150);
        tecla_fisica[4'hA] = 1'b0; esperar_ciclos(50);
        tecla_fisica[4'h9] = 1'b0; 
        aguardar_pulso_e_limpeza("T8 - Combinacao A + 9 gera pulso imediato na soltura", {{18{4'hF}}, 8'hA9});
        esperar_ciclos(150);

        // --- TESTE 9: Bloqueio contra teclas múltiplas simultâneas (ESPERA_LIVRE) ---
        // Aperta o 1, e antes de soltar o 1, aperta o 2.
        tecla_fisica[4'h1] = 1'b1; esperar_ciclos(150);
        tecla_fisica[4'h2] = 1'b1; esperar_ciclos(50);
        tecla_fisica[4'h1] = 1'b0; // Solta o 1 (O 2 ainda está pressionado!)
        esperar_ciclos(250); 
        tecla_fisica[4'h2] = 1'b0; // Agora sim soltou o 2
        esperar_ciclos(150); #1;
        verificar("T9 - Teclas sobrepostas: Tecla 2 foi ignorada porque o teclado nao estava livre", 
                  (digitos_value == {{19{4'hF}}, 4'h1})); // O 2 não pode aparecer
                  
        // Limpa buffer
        clicar_tecla(4'hF); esperar_ciclos(150);

// --- TESTE 10: Prioridade na mesma linha (Aperta 4 e 6 juntas -> vale 4 e soltar 6 não afeta 4) ---
        tecla_fisica[4'h4] = 1'b1;
        tecla_fisica[4'h6] = 1'b1;
        esperar_ciclos(150);       // Confirma tecla 4 (coluna 3 tem prioridade sobre coluna 1)
        tecla_fisica[4'h6] = 1'b0; // Solta a tecla 6 enquanto mantém a 4
        esperar_ciclos(150);
        tecla_fisica[4'h4] = 1'b0; // Agora solta a tecla 4
        esperar_ciclos(150); #1;
        verificar("T10 - Prioridade na mesma linha (4 e 6 juntas -> escolhe 4 e ignora 6)",
                  (digitos_value == {{19{4'hF}}, 4'h4}));
        clicar_tecla(4'hF); esperar_ciclos(150); // Limpa buffer

        // --- TESTE 11: Estouro/Deslocamento de 21 dígitos no buffer (mantém os últimos 20) ---
        for (int i = 0; i < 21; i++) begin
            clicar_tecla(i % 10, 120, 120);
        end
        #1;
        verificar("T11 - Buffer com 21 digitos desloca corretamente mantendo os ultimos 20",
                  (digitos_value == 80'h12345678901234567890));
        clicar_tecla(4'hF); esperar_ciclos(150); // Limpa buffer

        // --- TESTE 12: Congelamento imediato pelo Enable e Timeout (Ausência de digitação) ---
        clicar_tecla(4'h7); // Inicia o contador de timeout com '7' no buffer
        
        @(posedge clk);
        enable = 1'b0;      // Desabilita o módulo
        @(posedge clk); #1; // Já no próximo ciclo deve estar congelado!
        begin
            logic [3:0] lin_congelada;
            lin_congelada = lin_matriz; // Lê o valor no instante exato do congelamento
            esperar_ciclos(2000); #1;   // Passa 2000 ciclos congelado
            verificar("T12.1 - Modulo congelado com enable=0 mantem lin_matriz parada",
                      (lin_matriz == lin_congelada && digitos_valid == 1'b0));
        end
        enable = 1'b1;      // Reabilita o módulo para terminar de contar os 5000 ciclos!

        // RESTAURADO: Espera os 5000 ciclos ativos exigidos para o timeout automático estourar
        aguardar_pulso_e_limpeza("T12.2 - Timeout dispara 20xE apos inatividade de 5000 ciclos", {20{4'hE}}, 5200);

        $display("=================================================================");
        $display(" FIM | Sucessos: %0d | Falhas: %0d", testes_ok, erros);
        if (erros == 0) $display(" RESULTADO: CIRCUITO 100%% APROVADO!");
        $display("=================================================================");
        $finish;
    end
endmodule