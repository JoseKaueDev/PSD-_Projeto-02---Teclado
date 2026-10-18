// =============================================================================
// README - TESTBENCH SEQUENCIAL DO decodificador_de_teclado
// =============================================================================
//
// O QUE ESTE TESTBENCH FAZ
//   Simula fisicamente um teclado 4x4 ligado ao módulo, aciona as teclas passo
//   a passo de forma sequencial e confere imediatamente
//   se a saída está correta no ciclo esperado.
//
// ENTRADAS DO MÓDULO (o testbench GERA)
//   clk         clock. O módulo só conta ciclos: 1 ciclo = 1 período do clock.
//   rst         reset assíncrono (1 = reset).
//   enable      habilita/desabilita o módulo. Usado no teste de congelamento.
//   col_matriz  colunas do teclado, geradas pelo emulador do teclado:
//               0 = tecla apertada na linha que está ativa; 1111 = nenhuma tecla.
//
// SAÍDAS DO MÓDULO (o testbench OBSERVA)
//   lin_matriz    linha ativa da varredura (0111 -> 1011 -> 1101 -> 1110 -> 0111...).
//   digitos_value buffer de 20 dígitos hexa (80 bits).
//   digitos_valid pulso de 1 ciclo quando acontece um evento de confirmação ou erro.
//
// SINAIS CRIADOS PELO TESTBENCH
//   tecla_fisica  1 bit por tecla (1 = dedo na tecla). 
//                 Bits 0 a 9 = dígitos | 10=A  11=B  12=C  13=D  14=*  15=#
//   erros         quantidade total de falhas na simulação.
//   testes_ok     quantidade de verificações que passaram com sucesso.
//
// BLOCOS DO TESTBENCH
//   1. Emulador Físico: transforma o estado "tecla_fisica" em sinais "col_matriz".
//   2. Tasks de Estímulo: aplicam ações no tempo (esperar_ciclos, clicar_tecla).
//   3. Tasks de Conferência: "verificar" (checa valores silenciosos no buffer) e 
//      "aguardar_pulso_e_limpeza" (espera o pulso de valid e checa o valor exato).
//   4. Sequência Principal: O bloco "initial" contendo cronologicamente os Testes.
//
// COMO A CONFERÊNCIA FUNCIONA
//   O testbench avança no tempo e analisa a saída instantaneamente. 
//   - Para transições de buffer (entradas numéricas normais), usa-se a task "verificar".
//   - Para eventos como '*', '#', letras e Timeout, usa-se a task "aguardar_pulso_e_limpeza". 
//     Ela escuta o barramento até "digitos_valid" subir para 1, checa o valor 
//     de "digitos_value" e garante que no ciclo imediatamente seguinte o valor
//     retorna para 20 x F e o pulso cai para 0.
//
// O QUE É APONTADO COMO ERRO
//   - Valor errado no buffer silencioso ou durante um pulso.
//   - Pulso (valid=1) que não acontece dentro do tempo máximo estipulado.
//   - Falha de limpeza (o módulo esquecer de derrubar valid para 0 e limpar para 20xF).
//
// TESTES
//   T1  Reset e estado inicial             T7  Letra B anulada por intrometido
//   T2  Rejeição de ruído (quique)         T8  Combinação A + número
//   T3  Dígitos 1, 2, 3 e conf. com *      T9  Bloqueio de teclas sobrepostas
//   T4  Auto-repetição (Tp > 2000)         T10 Prioridade na mesma linha
//   T5  Tecla '#' e cancelamento de buf.   T11 Estouro e deslocamento de 21 díg.
//   T6  Letras C e A por >= 5000 ciclos    T12 Congelamento por enable e Timeout
//
// RESULTADO
//   Cada checagem imprime [OK] ou [ERRO]. O resumo final contabiliza as falhas 
//   e exibe "RESULTADO: CIRCUITO 100% APROVADO!" se estiver perfeitamente liso.
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
        esperar_ciclos(4500);         // Garante que B fique >= 5000 ciclos pressionada no total!
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