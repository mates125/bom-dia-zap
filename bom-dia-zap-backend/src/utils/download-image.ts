import axios from 'axios';
import { randomUUID } from 'crypto';
import * as path from 'path';
import sharp from 'sharp';

export async function downloadImage(url: string) {
  const response = await axios({
    url,
    method: 'GET',
    responseType: 'arraybuffer',
  });

  const filename = `${randomUUID()}.jpg`;

  const originalPath = path.join(
    process.cwd(),
    'uploads',
    'original',
    filename,
  );

  const thumbPath = path.join(process.cwd(), 'uploads', 'thumb', filename);

  await sharp(response.data)
    .jpeg({
      quality: 80,
    })
    .resize({
      width: 1200,
      withoutEnlargement: true,
    })
    .toFile(originalPath);

  await sharp(response.data)
    .jpeg({
      quality: 70,
    })
    .resize({
      width: 300,
      withoutEnlargement: true,
    })
    .toFile(thumbPath);

  return {
    filename,

    originalUrl: `http://localhost:3000/uploads/original/${filename}`,

    thumbUrl: `http://localhost:3000/uploads/thumb/${filename}`,
  };
}
