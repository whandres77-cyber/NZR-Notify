# NZR Notify — V1 Premium

Central multi-igrejas / multiempresas com WhatsApp como canal principal.

## Visual Premium
- Interface Material 3 personalizada
- Modo claro, escuro ou automático
- Identidade visual por organização
- Splash/loading animado
- Transições suaves entre módulos
- Cards com entrada em cascata
- Contadores animados
- Status pulsante da central
- Dashboard premium com destaques
- Prévia visual de mensagens do WhatsApp
- Bottom sheets com blur
- Preview instantâneo da marca da igreja/empresa

## Estrutura
- `mobile/`: app Flutter (Android agora, iOS depois)
- `backend/`: API Node.js + PostgreSQL
- `docs/`: arquitetura e fluxo de negócio

## Recursos
- Multi-organização
- Logo/nome/cor por igreja ou empresa
- Tema claro, escuro ou automático
- Agenda de cultos/eventos
- Banner por evento
- Contatos segmentados
- Consentimento (opt-in) por contato
- Campanhas e lembretes agendados
- Templates de WhatsApp
- Scheduler automático
- Integração oficial com WhatsApp Business Platform via variáveis de ambiente
- Dashboard de campanhas, eventos e contatos

> A automação de WhatsApp Channels deve ser ligada apenas quando houver suporte oficial correspondente na conta/API da Meta. A plataforma separa publicações de canal dos avisos diretos via WhatsApp Business.
