# PSD_Projeto 02 - Decodificador de Teclado Matricial 4x4

Um controlador robusto em hardware puro (RTL) para decodificação de teclado matricial 4x4. Desenvolvido em SystemVerilog, este módulo vai muito além de uma simples varredura, gerenciando restrições físicas reais como *debounce*, detecção de múltiplas teclas e sequências temporais complexas (auto-repetição, pressionamento longo e timeout).

Projeto desenvolvido por José Kauê Alves Monteiro Silva, como parte das atividades de Engenharia de Computação no Instituto Federal da Paraíba (IFPB) - Campus Campina Grande.

## 🚀 Funcionalidades Principais

A Máquina de Estados Finita (FSM) de 21 estados garante um funcionamento livre de falhas elétricas e erros humanos:

*   **Filtro de Ruído (Debounce):** Rejeita ruídos elétricos e quiques mecânicos menores que 100 ciclos de clock em pressionamentos e solturas.
*   **Varredura Segura e Anti-Ghosting:** Monitoramento contínuo das 4 linhas (`ciclos_livre`). Teclas sobrepostas (como o dedo escorregar de uma tecla para outra) são ignoradas para evitar entradas corrompidas.
*   **Auto-Repetição Numérica:** Teclas numéricas seguradas sofrem auto-repetição após 2000 ciclos, repetindo a cada 1000 ciclos subsequentes.
*   **Pressionamento Longo:** Teclas literais (B, C, D) exigem um pressionamento contínuo mínimo de 5000 ciclos para serem validadas, sendo instantaneamente anuladas caso um número intruso seja pressionado junto.
*   **Combinações Especiais (`A + n`):** Capacidade de manter a tecla `A` pressionada, digitar um ou mais números e enviar a combinação baseada na última tecla válida ao soltar.
*   **Timeout:** Limpeza automática do barramento (`20 x E`) após 5000 ciclos absolutos de inatividade do usuário.

## ⚙️ Interface do Módulo (DUT)

| Porta | Direção | Largura | Descrição |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Clock de referência (1 kHz). 1 ciclo = 1 ms. |
| `rst` | Input | 1 bit | Reset assíncrono (ativo em alto). |
| `enable` | Input | 1 bit | Congela (0) ou executa (1) o módulo. |
| `col_matriz` | Input | 4 bits | Leitura das colunas com pull-up (0 = pressionada). |
| `lin_matriz` | Output | 4 bits | Varredura ativa em 0 (uma linha ativada por ciclo). |
| `digitos_value`| Output | 80 bits | Buffer contendo até 20 dígitos hexa (tipo `digitosPac_t`). |
| `digitos_valid`| Output | 1 bit | Pulso de exato 1 ciclo confirmando a entrega de um evento. |

## 🧪 Verificação: Testbench Sequencial (Task-Based)

Para garantir o funcionamento blindado do circuito, foi desenvolvido um **Testbench Sequencial Orientado a Tarefas**. Em vez de injetar eventos de forma caótica, o testbench emula fisicamente um dedo humano acionando o teclado no tempo.

Foram implementadas tarefas de verificação síncronas (`aguardar_pulso_e_limpeza`) que não só validam o valor do barramento durante o pulso, mas também garantem que o ciclo imediatamente subsequente force a limpeza para `20 x F`.

### Cobertura de Testes
O conjunto de validação `TbTeclado.sv` testa 12 cenários críticos:
*   **T1:** Reset e estabilidade inicial.
*   **T2:** Rejeição de ruído/quique mecânico (< 100 ciclos).
*   **T3:** Digitação encadeada no buffer e confirmação imediata com `*`.
*   **T4:** Auto-repetição por pressionamento longo.
*   **T5:** Descarte forçado de buffer ativo pela tecla `#`.
*   **T6:** Confirmação de teclas Especiais por tempo longo (>= 5000 ciclos).
*   **T7:** Anulação de tecla especial devido a entrada intrusa na matriz.
*   **T8:** Combinação `A + Número` (espera soltura mútua).
*   **T9:** Bloqueio contra teclas múltiplas ativadas simultaneamente.
*   **T10:** Prioridade de leitura mecânica na mesma linha da matriz.
*   **T11:** Estouro de buffer (deslocamento dos 21 dígitos com retenção dos últimos 20).
*   **T12:** Congelamento imediato pelo pino de `enable` e disparo de Timeout de inatividade.

## 🛠️ Como Simular e Visualizar (EDA Playground)

O código está pronto para ser compilado e simulado em plataformas web como o [EDA Playground](https://www.edaplayground.com/) ou softwares como o ModelSim/Icarus Verilog.

1.  Crie os arquivos `decodificador_de_teclado.sv` e `tb_decodificador_de_teclado.sv`.
2.  Defina o pacote `teclado_pkg` no topo do código (fornecido na fonte).
3.  Utilize o simulador **Aldec Riviera Pro** ou **Icarus Verilog 0.9.7**.
4.  Para exportar as formas de onda, assegure-se de que o bloco de *dump* (abaixo) esteja presente no seu `initial` de configuração e ative a caixa **Open EPWave after run**.

```systemverilog
initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb_decodificador_de_teclado);
end
