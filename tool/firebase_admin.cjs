// Usa la sesión existente de Firebase CLI. No guarda ni imprime credenciales.
const path = require('node:path');
const cli = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const auth = require(path.join(cli, 'auth.js'));
const project = 'pokechafa';

async function main() {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Inicia sesión con firebase login.');
  const credentials = await auth.getAccessToken(account.tokens.refresh_token, [
    'https://www.googleapis.com/auth/cloud-platform',
  ]);
  async function api(url, method = 'GET', body) {
    const response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${credentials.access_token}`,
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(30000),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(`${response.status}: ${result.error?.message}`);
    return result;
  }
  const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
  function fields(value) {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, encode(item)]));
  }
  function encode(value) {
    if (typeof value === 'string') return {stringValue: value};
    if (typeof value === 'number') return {integerValue: String(value)};
    if (typeof value === 'boolean') return {booleanValue: value};
    if (Array.isArray(value)) return {arrayValue: {values: value.map(encode)}};
    return {mapValue: {fields: fields(value)}};
  }
  if (process.argv[2] === 'catalogo') {
    const catalogo = [
      {id: 'nubin', nombre: 'Nubin', tipo: 'Aire', simbolo: 'nube', descripcion: 'Una criatura de aire con forma de nube.'},
      {id: 'burbujin', nombre: 'Burbujin', tipo: 'Agua', simbolo: 'agua', descripcion: 'Una criatura de agua que forma burbujas.'},
      {id: 'estelin', nombre: 'Estelin', tipo: 'Estrella', simbolo: 'estrella', descripcion: 'Una criatura con forma de estrella.'},
    ];
    for (const {id, ...datos} of catalogo) {
      const response = await fetch(`${base}/criaturas/${id}`, {
        headers: {Authorization: `Bearer ${credentials.access_token}`},
      });
      if (response.ok) {
        console.log(`${id}: existente`);
        continue;
      }
      if (response.status !== 404) throw new Error(`No se pudo consultar ${id}: ${response.status}`);
      await api(`${base}/criaturas/${id}?currentDocument.exists=false`, 'PATCH', {
        fields: {
          ...fields({...datos, creadorId: 'catalogo', dibujo: [], version: 1}),
          creadaEn: {timestampValue: new Date().toISOString()},
          actualizadaEn: {timestampValue: new Date().toISOString()},
        },
      });
      console.log(`${id}: migrada a Firestore`);
    }
  }
  if (process.argv[2] === 'inspect') {
    const collections = await api(`${base}:listCollectionIds`, 'POST', {});
    console.log('Colecciones:', collections.collectionIds || []);
    const release = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
    const rules = await api(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
    console.log('Reglas actuales:', JSON.stringify(rules.source.files));
    const config = await api(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`);
    console.log('Correo habilitado:', config.signIn?.email?.enabled);
    const providers = await api(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/defaultSupportedIdpConfigs`);
    console.log('Proveedores:', (providers.defaultSupportedIdpConfigs || []).map(p => ({id: p.name.split('/').pop(), enabled: p.enabled})));
  }
}

main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
