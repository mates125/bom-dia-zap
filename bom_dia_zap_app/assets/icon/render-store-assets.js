const path = require('path');
const sharp = require(path.join(__dirname, '../../../bom-dia-zap-backend/node_modules/sharp'));

const dir = __dirname;

async function run() {
  // Ícone de alta resolução exigido pela Play Console (512x512).
  await sharp(path.join(dir, 'icon-main.png'))
    .resize(512, 512)
    .png()
    .toFile(path.join(dir, 'icon-512.png'));

  // Imagem de destaque (feature graphic), 1024x500.
  await sharp(path.join(dir, 'feature-graphic.svg'))
    .resize(1024, 500)
    .png()
    .toFile(path.join(dir, 'feature-graphic.png'));

  console.log('done');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
