const fs = require('fs');
const path = require('path');
const { CredentialManager } = require('../utils/credential-manager');
const { Database } = require('../database/db');

async function main() {
  const file = process.argv[2];
  if (!file) throw new Error('Setup payload missing.');
  const payload = JSON.parse(fs.readFileSync(file, 'utf8'));
  const cm = new CredentialManager();
  await cm.loadCredentials();
  await cm.loadTokens();

  const p = payload.aiProvider;
  if (p && p.apiKey) {
    if (p.id === 'gemini') cm.credentials.gemini = { apiKey: p.apiKey, model: p.model };
    else cm.credentials.aiProvider = { provider: p.id, apiKey: p.apiKey, model: p.model };
  }

  const v = payload.videoProvider;
  const saveVideo = {
    seedance: c => { cm.credentials.replicate = { ...(cm.credentials.replicate || {}), apiKey: c.key }; },
    minimax_h3: c => { cm.credentials.minimax = { apiKey: c.key }; },
    google_omni: c => { cm.credentials.gemini = { ...(cm.credentials.gemini || {}), apiKey: c.key }; },
    kling: c => { cm.credentials.kling = { accessKey: c.key, secretKey: c.secret }; },
    wan: c => { cm.credentials.wan = { apiKey: c.key }; }
  };
  if (v && v.id !== 'slideshow' && v.key && saveVideo[v.id]) saveVideo[v.id](v);

  const y = payload.youtube;
  if (y && y.clientId) {
    cm.credentials.youtube = {
      client_id: y.clientId,
      client_secret: y.clientSecret || '',
      redirect_uris: ['http://127.0.0.1']
    };
  }

  const c = payload.channel || {};
  const oldChannel = cm.credentials.channel || {};
  cm.credentials.channel = {
    ...oldChannel,
    channelName: c.channelName || oldChannel.channelName || 'My Automated Channel',
    channelDescription: oldChannel.channelDescription || 'Automated content channel',
    defaultCategory: oldChannel.defaultCategory || '22',
    defaultPrivacy: c.privacy || oldChannel.defaultPrivacy || 'private'
  };
  const oldContent = cm.credentials.content || {};
  cm.credentials.content = {
    contentTypes: oldContent.contentTypes || ['tutorial', 'explainer', 'list'],
    competitorChannels: oldContent.competitorChannels || [],
    targetAudience: c.targetAudience || oldContent.targetAudience || 'General audience interested in educational content',
    postingFrequency: c.frequency || oldContent.postingFrequency || 'daily',
    preferredPostTime: oldContent.preferredPostTime || '14:00'
  };

  await cm.saveCredentials();

  const envPath = path.join(__dirname, '..', '.env');
  let env = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
  const envSet = (key, value) => {
    const lines = env.split(/\r?\n/).filter(line => !line.startsWith(key + '='));
    lines.push(key + '=' + String(value ?? ''));
    env = lines.filter(Boolean).join('\n') + '\n';
  };
  envSet('DEFAULT_PRIVACY_STATUS', c.privacy || 'private');
  fs.writeFileSync(envPath, env);

  const db = new Database();
  await db.initialize();
  await db.setSetting('video_provider', (v && v.id) || 'slideshow');
  await db.close();

  if (y && y.authenticate && y.clientId) {
    const { ModernAuth } = require('../modern-auth');
    const auth = new ModernAuth();
    await auth.authenticate();
    await auth.testAuthentication();
  }
}
main().catch(error => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
