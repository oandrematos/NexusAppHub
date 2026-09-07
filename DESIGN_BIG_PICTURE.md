# Nexus App Hub — Especificação de Design: Modo Big Picture (10-Foot UI)
**Autor:** Agente Pixel (Chefe de Design, UI/UX e Identidade Visual)  
**Destinatários:** Agente Citadel (Engenheiro-Chefe da Loja) & Diretor André  
**Operação:** Gamepad Sovereign  
**Data:** 07 de Setembro de 2026  

---

## 1. Visão Geral & Ergonomia de Sala (10-Foot Experience)
O **Modo Big Picture** da Nexus App Hub é projetado especificamente para telas de TV e monitores widescreen a uma distância de 2 a 4 metros, controlado **100% via Gamepad (Xbox X-Input e PS4 DualShock 4)** sem necessidade de mouse ou teclado.

---

## 2. Princípios de Interface

### Proporções & Tipografia para TV
- **Tamanho Mínimo de Fonte:** 20sp para metadados secundários; 28sp para títulos de cards; 44sp para cabeçalhos de seções.
- **Contraste AMOLED Puro:** Fundo escuro profundo (`#060912` a `#0A0F1E`) para compatibilidade e economia máxima em painéis OLED/AMOLED.
- **Área de Segurança (Safe Margins):** Margem externa mínima de 48px em 1080p (96px em 4K) para evitar corte em TVs antigas (*overscan*).

---

## 3. Comportamento do Foco Dinâmico (Gamepad Navigation)

```
        ┌────────────────────────────────────────────────────────┐
        │  [ CARD COM FOCO ATIVO ]                               │
        │  • Escala: 1.08x (Animação de 180ms - easeOutCubic)    │
        │  • Borda Neon: 3.5px com Cyan Glow (#00F0FF)           │
        │  • Sombra Projetada: Elevation 16 com Blur de 24px     │
        └────────────────────────────────────────────────────────┘
```

### Regras de Interação Visual:
1. **Transição de Foco Instantânea:** Ao mover o D-Pad ou o analógico esquerdo, o foco pula com som sutil e efeito de luz na borda do card seguinte.
2. **Auto-Scroll Centralizado:** Ao navegar em carrosséis horizontais, o item focado sempre se alinha suavemente ao centro ou terço inicial da tela.
3. **Cards Grandes (16:9 e 2:1):**
   - **Hero Carousel:** 1120x480 (banner cinematográfico com títulos translúcidos).
   - **Fileiras de Apps (Category Rows):** 380x214 (usando os `banner_card.png` ultraleves de 640x360).

---

## 4. Barra de Ações Inferior (Action HUD Bar)

A parte inferior da tela exibe permanentemente a barra de atalhos contextuais com os ícones de botões gerados pelo **Nexus Creative Studio** (`assets/gamepad/`):

### Padrão Xbox (X-Input):
- `[xbox_a.png]` **Entrar / Instalar**
- `[xbox_b.png]` **Voltar**
- `[xbox_x.png]` **Ver Screenshots / Mídia**
- `[xbox_y.png]` **Buscar na Loja**
- `[xbox_lb.png]` / `[xbox_rb.png]` **Alternar Abas (Jogos, Apps, Linux, Ferramentas)**
- `[xbox_menu.png]` **Filtros / Configurações**

### Padrão PlayStation 4 (DualShock 4):
- `[ps_cross.png]` **Confirmar / Instalar**
- `[ps_circle.png]` **Voltar**
- `[ps_square.png]` **Ver Screenshots**
- `[ps_triangle.png]` **Buscar**
- `[ps_l1.png]` / `[ps_r1.png]` **Categorias**
- `[ps_options.png]` **Menu**

*Detecção Automática:* A loja detecta o tipo de controle conectado e renderiza o conjunto correspondente (`xbox_*` ou `ps_*`) dinamicamente.

---

## 5. Estrutura dos Assets Disponibilizados

Todos os 30 prompts visuais estão forjados em alta definição e depositados em:
- `NexusAppHub_dev/assets/gamepad/`
- `SnakeGame_dev/assets/gamepad/`
- `NeoBlocks_dev/assets/gamepad/`
- `SuperPong_dev/assets/gamepad/`
- `SpaceDuel_dev/assets/gamepad/`
- Repositório Compartilhado: `Nexus_Gamepad_Assets/`
