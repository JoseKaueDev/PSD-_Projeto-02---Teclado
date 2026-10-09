# PSD | Projeto 02 - Teclado ⌨️

![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-warning)
![Linguagem](https://img.shields.io/badge/Linguagem-SystemVerilog-blue)

> **Aviso:** Este projeto é um trabalho em andamento (Work in Progress). As implementações atuais servem como base estrutural e o repositório será atualizado futuramente com a versão final e validada do sistema.

## 📖 Sobre o Projeto

Este repositório armazena os arquivos do **Projeto 02 - Teclado**, focado no desenvolvimento e projeto de sistemas digitais. O objetivo central é implementar um **decodificador de teclado matricial** robusto utilizando a linguagem de descrição de hardware **SystemVerilog**.

O circuito foi projetado para ler uma matriz de botões (entradas de linhas e colunas) e traduzir as interações físicas em valores lógicos compreensíveis pelo sistema. A arquitetura é centrada em uma Máquina de Estados Finita (FSM) que gerencia todo o fluxo de dados e rotinas de hardware.

## ✨ Principais Funcionalidades (Previstas)

- **Varredura (Scanning) Contínua:** Identificação em tempo real de teclas pressionadas na matriz.
- **Debounce de Hardware:** Tratamento de ruídos e trepidações mecânicas dos botões, garantindo que cada pressionamento seja lido apenas uma vez.
- **Mapeamento Hexadecimal:** Identificação de números (0 a 9), letras (A a F) e funções especiais (representadas por teclas como `*` e `#`).
- **Sistema de Timeout:** Gestão de tempo limite para cancelar operações em caso de inatividade do usuário.
- **Buffer e Confirmação:** Armazenamento temporário dos dígitos inseridos até que a confirmação da entrada seja feita.

## 🛠️ Tecnologias Utilizadas

- **SystemVerilog:** Linguagem principal para descrição do hardware.
- **Simulador / Ferramentas:** (Ex: EDA Playground, ModelSim, Quartus - *Atualize com a ferramenta que você está usando*)

## 🚧 Próximos Passos (To-Do)

- [ ] Finalizar a lógica e as transições da Máquina de Estados (FSM).
- [ ] Implementar e ajustar os temporizadores de Debounce e Timeout.
- [ ] Criar módulos de *Testbench* para simulação do decodificador.
- [ ] Validar formas de onda e respostas aos estímulos da matriz de botões.
- [ ] Sintetizar o projeto (se aplicável) e elaborar a documentação final.


