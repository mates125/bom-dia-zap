import { Injectable } from '@nestjs/common';
import axios from 'axios';

export interface StockPhoto {
  id: number;
  photoUrl: string;
  downloadUrl: string;
  photographer: string;
}

const PEXELS_SEARCH_URL = 'https://api.pexels.com/v1/search';
const RESULTS_PER_PAGE = 15;
const MAX_RANDOM_PAGE = 20;

interface PexelsPhoto {
  id: number;
  url: string;
  photographer: string;
  src: { large2x: string };
}

interface PexelsSearchResponse {
  photos: PexelsPhoto[];
}

@Injectable()
export class PexelsProvider {
  async searchPhotos(query: string): Promise<StockPhoto[]> {
    const apiKey = process.env.PEXELS_API_KEY;

    if (!apiKey) {
      throw new Error(
        'PEXELS_API_KEY não configurada. Crie uma chave gratuita em pexels.com/api e defina no .env',
      );
    }

    const page = 1 + Math.floor(Math.random() * MAX_RANDOM_PAGE);

    const response = await axios.get<PexelsSearchResponse>(PEXELS_SEARCH_URL, {
      headers: { Authorization: apiKey },
      params: {
        query,
        per_page: RESULTS_PER_PAGE,
        page,
        orientation: 'portrait',
      },
    });

    const photos = response.data.photos ?? [];

    return photos.map((photo) => ({
      id: photo.id,
      photoUrl: photo.url,
      downloadUrl: photo.src.large2x,
      photographer: photo.photographer,
    }));
  }
}
