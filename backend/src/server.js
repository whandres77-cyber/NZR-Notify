import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { pool, initDb } from './db.js';
import { startScheduler } from './scheduler.js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (req, res) => res.json({ ok: true, service: 'NZR Notify API' }));

app.get('/api/organizations', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM organizations ORDER BY id');
  res.json(rows);
});

app.post('/api/organizations', async (req, res) => {
  const { name, logo_url, primary_color = '#7C3AED', theme_mode = 'system', whatsapp_name, whatsapp_phone } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO organizations (name, logo_url, primary_color, theme_mode, whatsapp_name, whatsapp_phone)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [name, logo_url || null, primary_color, theme_mode, whatsapp_name || null, whatsapp_phone || null]
  );
  res.status(201).json(rows[0]);
});

app.patch('/api/organizations/:id', async (req, res) => {
  const id = Number(req.params.id);
  const current = (await pool.query('SELECT * FROM organizations WHERE id=$1', [id])).rows[0];
  if (!current) return res.status(404).json({ error: 'Organização não encontrada' });
  const next = { ...current, ...req.body };
  const { rows } = await pool.query(
    `UPDATE organizations SET name=$1, logo_url=$2, primary_color=$3, theme_mode=$4, whatsapp_name=$5, whatsapp_phone=$6 WHERE id=$7 RETURNING *`,
    [next.name, next.logo_url, next.primary_color, next.theme_mode, next.whatsapp_name, next.whatsapp_phone, id]
  );
  res.json(rows[0]);
});

app.get('/api/organizations/:orgId/events', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM events WHERE organization_id=$1 ORDER BY starts_at DESC', [Number(req.params.orgId)]);
  res.json(rows);
});

app.post('/api/organizations/:orgId/events', async (req, res) => {
  const { title, description, banner_url, location_text, starts_at, reminder_minutes = [1440,180,60] } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO events (organization_id,title,description,banner_url,location_text,starts_at,reminder_minutes)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [Number(req.params.orgId), title, description || null, banner_url || null, location_text || null, starts_at, reminder_minutes]
  );
  res.status(201).json(rows[0]);
});

app.get('/api/organizations/:orgId/contacts', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM contacts WHERE organization_id=$1 ORDER BY id DESC', [Number(req.params.orgId)]);
  res.json(rows);
});

app.post('/api/organizations/:orgId/contacts', async (req, res) => {
  const { name, phone, segment = 'Todos', opt_in = false } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO contacts (organization_id,name,phone,segment,opt_in) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [Number(req.params.orgId), name, phone, segment, Boolean(opt_in)]
  );
  res.status(201).json(rows[0]);
});

app.get('/api/organizations/:orgId/campaigns', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM campaigns WHERE organization_id=$1 ORDER BY scheduled_for DESC', [Number(req.params.orgId)]);
  res.json(rows);
});

app.post('/api/organizations/:orgId/campaigns', async (req, res) => {
  const { event_id, segment = 'Todos', title, body, banner_url, scheduled_for, channel = 'whatsapp_dm' } = req.body;
  const { rows } = await pool.query(
    `INSERT INTO campaigns (organization_id,event_id,segment,title,body,banner_url,scheduled_for,channel)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [Number(req.params.orgId), event_id || null, segment, title, body, banner_url || null, scheduled_for, channel]
  );
  res.status(201).json(rows[0]);
});

app.get('/api/organizations/:orgId/stats', async (req, res) => {
  const orgId = Number(req.params.orgId);
  const contacts = (await pool.query('SELECT COUNT(*)::int count FROM contacts WHERE organization_id=$1', [orgId])).rows[0].count;
  const opted = (await pool.query('SELECT COUNT(*)::int count FROM contacts WHERE organization_id=$1 AND opt_in=TRUE', [orgId])).rows[0].count;
  const upcoming = (await pool.query('SELECT COUNT(*)::int count FROM events WHERE organization_id=$1 AND starts_at >= NOW()', [orgId])).rows[0].count;
  const scheduled = (await pool.query("SELECT COUNT(*)::int count FROM campaigns WHERE organization_id=$1 AND status='scheduled'", [orgId])).rows[0].count;
  res.json({ contacts, opted_in: opted, upcoming_events: upcoming, scheduled_campaigns: scheduled });
});

await initDb();
startScheduler();
const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`NZR Notify API em http://localhost:${port}`));
