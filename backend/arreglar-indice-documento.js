// Script de UNA SOLA VEZ: arregla el índice único de documentoIdentidad en MongoDB.
//
// Problema: el índice actual (documentoIdentidad_1) trata el valor vacío (null) como un
// documento más, así que solo puede existir UNA cuenta sin documento. Por eso fallaba
// crear una cuenta nueva con Google.
//
// Solución: el índice solo vigila los documentos que SÍ tienen número. Las cuentas sin
// documento pueden ser las que sean, y un documento real no se puede repetir.
//
// Uso (desde la carpeta donde está server.js):
//   node scripts/arreglar-indice-documento.js
//
// No borra ni modifica ningún usuario: solo cambia el índice.

import 'dotenv/config';
import dns from 'dns';
import mongoose from 'mongoose';

// Mismo fix de DNS que usa server.js
dns.setServers(['8.8.8.8', '8.8.4.4']);

const NOMBRE_INDICE = 'documentoIdentidad_1';

const mostrarIndices = (lista) =>
  console.table(
    lista.map((i) => ({
      nombre: i.name,
      llave: JSON.stringify(i.key),
      unico: Boolean(i.unique),
      sparse: Boolean(i.sparse),
      parcial: i.partialFilterExpression ? JSON.stringify(i.partialFilterExpression) : ''
    }))
  );

async function main() {
  if (!process.env.MONGO_URI) {
    throw new Error('Falta MONGO_URI en el archivo .env');
  }

  await mongoose.connect(process.env.MONGO_URI, { dbName: 'spa_vehicular' });
  const usuarios = mongoose.connection.collection('users');

  console.log('\nÍndices ANTES:');
  const antes = await usuarios.indexes();
  mostrarIndices(antes);

  // Antes de tocar nada, se revisa que no haya dos cuentas con el mismo documento real
  const repetidos = await usuarios
    .aggregate([
      { $match: { documentoIdentidad: { $gt: '' } } },
      { $group: { _id: '$documentoIdentidad', total: { $sum: 1 }, correos: { $push: '$correo' } } },
      { $match: { total: { $gt: 1 } } }
    ])
    .toArray();

  if (repetidos.length > 0) {
    console.log('\n⚠️  Hay documentos repetidos en más de una cuenta. Corrígelos y vuelve a correr el script:');
    console.log(JSON.stringify(repetidos, null, 2));
    return;
  }

  if (antes.some((i) => i.name === NOMBRE_INDICE)) {
    await usuarios.dropIndex(NOMBRE_INDICE);
    console.log(`\n🗑️  Índice viejo "${NOMBRE_INDICE}" eliminado`);
  }

  await usuarios.createIndex(
    { documentoIdentidad: 1 },
    {
      name: NOMBRE_INDICE,
      unique: true,
      partialFilterExpression: { documentoIdentidad: { $gt: '' } }
    }
  );
  console.log(`✅ Índice "${NOMBRE_INDICE}" creado de nuevo (único solo para documentos reales)`);

  console.log('\nÍndices DESPUÉS:');
  mostrarIndices(await usuarios.indexes());
}

main()
  .catch((error) => {
    console.error('❌ Error:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });