import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8010';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 120000,
});

export async function uploadPdf(file) {
  const formData = new FormData();
  formData.append('file', file);

  const response = await apiClient.post('/api/pdfs', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });

  return response.data;
}

export async function exportPdf(fileId, payload) {
  const response = await apiClient.post(`/api/pdfs/${fileId}/export`, payload, {
    responseType: 'blob',
  });

  return {
    blob: response.data,
    filename: filenameFromDisposition(response.headers['content-disposition']) ?? 'merged.pdf',
  };
}

export function thumbnailUrl(fileId, pageNumber, width = 240) {
  const url = new URL(`/api/pdfs/${fileId}/pages/${pageNumber}/thumbnail`, API_BASE_URL);
  url.searchParams.set('width', String(width));
  return url.toString();
}

function filenameFromDisposition(disposition) {
  if (!disposition) {
    return null;
  }

  const utf8Match = disposition.match(/filename\\*=UTF-8''([^;]+)/i);
  if (utf8Match) {
    return decodeURIComponent(utf8Match[1]);
  }

  const asciiMatch = disposition.match(/filename="?([^";]+)"?/i);
  return asciiMatch?.[1] ?? null;
}
