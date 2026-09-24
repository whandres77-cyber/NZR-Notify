import cron from 'node-cron';
import { pool } from './db.js';
import { sendWhatsAppText } from './whatsapp.js';

export function startScheduler() {
  cron.schedule('* * * * *', async () => {
    const client = await pool.connect();
    try {
      const { rows: campaigns } = await client.query(`
        SELECT * FROM campaigns
        WHERE status = 'scheduled' AND channel = 'whatsapp_dm' AND scheduled_for <= NOW()
        ORDER BY scheduled_for ASC
        LIMIT 20
      `);

      for (const campaign of campaigns) {
        await client.query('UPDATE campaigns SET status = $1 WHERE id = $2', ['sending', campaign.id]);

        const params = [campaign.organization_id];
        let where = 'organization_id = $1 AND opt_in = TRUE';
        if (campaign.segment !== 'Todos') {
          params.push(campaign.segment);
          where += ' AND segment = $2';
        }

        const { rows: contacts } = await client.query(`SELECT * FROM contacts WHERE ${where}`, params);
        for (const contact of contacts) {
          const text = `${campaign.title}\n\n${campaign.body}`;
          const result = await sendWhatsAppText({ to: contact.phone, body: text });
          await client.query(
            `INSERT INTO message_logs (organization_id, campaign_id, contact_id, status, provider_message_id, error)
             VALUES ($1,$2,$3,$4,$5,$6)`,
            [campaign.organization_id, campaign.id, contact.id, result.ok ? 'sent' : 'failed', result.id || null, result.error || null]
          );
        }

        await client.query(
          `UPDATE campaigns SET status = $1, sent_at = NOW() WHERE id = $2`,
          ['sent', campaign.id]
        );
      }
    } catch (e) {
      console.error('scheduler:', e);
    } finally {
      client.release();
    }
  });
}
