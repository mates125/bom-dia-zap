const path = require('path');
// Reuses the sharp install from the backend instead of adding a Flutter-side node_modules.
const sharp = require(path.join(__dirname, '../../../bom-dia-zap-backend/node_modules/sharp'));

const dir = __dirname;

async function run() {
  await sharp(path.join(dir, 'icon-foreground.svg'))
    .resize(1024, 1024)
    .png()
    .toFile(path.join(dir, 'icon-foreground.png'));

  await sharp(path.join(dir, 'icon-main.svg'))
    .resize(1024, 1024)
    .png()
    .toFile(path.join(dir, 'icon-main.png'));

  console.log('done');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
