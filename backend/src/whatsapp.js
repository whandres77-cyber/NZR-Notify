function configured() {
  return Boolean(process.env.WHATSAPP_ACCESS_TOKEN && process.env.WHATSAPP_PHONE_NUMBER_ID);
}

export async function sendWhatsAppText({ to, body }) {
  if (!configured()) {
    return { ok: false, demo: true, error: 'WhatsApp ainda não configurado no servidor.' };
  }

  const version = process.env.WHATSAPP_GRAPH_VERSION || 'v23.0';
  const url = `https://graph.facebook.com/${version}/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.WHATSAPP_ACCESS_TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to,
      type: 'text',
      text: { body }
    })
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) return { ok: false, error: JSON.stringify(data) };
  return { ok: true, id: data?.messages?.[0]?.id || null };
}
