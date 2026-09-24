# Arquitetura

## 1. App administrativo
Flutter, compartilhável entre Android e iOS.

## 2. Backend
Node.js + Express + PostgreSQL. Toda entidade possui `organization_id` para isolamento entre clientes.

## 3. WhatsApp
O backend envia mensagens pelo WhatsApp Business Platform usando:
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_GRAPH_VERSION`

A central só agenda contatos com `opt_in = true`.

## 4. Agenda
Um evento pode ter lembretes configurados em minutos antes do horário do culto/evento.
Ex.: 1440 (1 dia), 180 (3 horas), 60 (1 hora).

## 5. Multi-organização
Cada cliente possui:
- nome
- logo
- cor principal
- tema
- WhatsApp
- contatos
- eventos
- templates
- campanhas

## 6. Evolução
- Assinaturas e planos
- Super Admin NZR
- Métricas por organização
- Cloud Storage para banners
- OAuth da Meta
- Aprovação/gerenciamento de templates
- iOS
- Publicação em WhatsApp Channels, apenas se a API oficial suportar a operação desejada
