import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import * as fs from 'fs/promises';
import * as path from 'path';

let s3Client: S3Client | null = null;

function isR2Configured(): boolean {
  return Boolean(
    process.env.R2_ACCOUNT_ID &&
    process.env.R2_ACCESS_KEY_ID &&
    process.env.R2_SECRET_ACCESS_KEY &&
    process.env.R2_BUCKET_NAME &&
    process.env.R2_PUBLIC_URL,
  );
}

function getS3Client(): S3Client {
  if (!s3Client) {
    s3Client = new S3Client({
      region: 'auto',
      endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID!,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
      },
    });
  }

  return s3Client;
}

/**
 * Salva um arquivo e retorna a URL pública dele. Usa Cloudflare R2 quando
 * as variáveis R2_* estão configuradas (produção); caso contrário, grava
 * em disco local e serve via /uploads (dev local, sem precisar de conta
 * na Cloudflare pra rodar o projeto).
 */
export async function saveFile(
  buffer: Buffer,
  key: string,
  contentType: string,
): Promise<string> {
  if (isR2Configured()) {
    const client = getS3Client();

    await client.send(
      new PutObjectCommand({
        Bucket: process.env.R2_BUCKET_NAME,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      }),
    );

    return `${process.env.R2_PUBLIC_URL}/${key}`;
  }

  const filePath = path.join(process.cwd(), 'uploads', key);
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, buffer);

  const baseUrl = process.env.PUBLIC_BASE_URL ?? 'http://localhost:3000';
  return `${baseUrl}/uploads/${key}`;
}
