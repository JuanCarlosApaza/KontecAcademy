import { ValidationError } from '../errors.js';

/** Archivo del campo "image" (multipart, ya procesado por multer). */
export interface UploadImageDTO {
  buffer: Buffer;
  filename: string;
  contentType: string;
}

/** Archivo crudo que entrega multer (solo lectura de campos). */
export interface UploadedFile {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
}

/** Valida el archivo subido. Lanza [ValidationError]. */
export function parseUploadImageDTO(file: UploadedFile | undefined): UploadImageDTO {
  if (!file) {
    throw new ValidationError('Falta el campo "image"');
  }
  // El bucket "courses" solo acepta estos tipos (Supabase lo rechaza
  // después con un 500 genérico; mejor validarlo aquí con mensaje claro).
  if (file.mimetype !== 'image/jpeg' && file.mimetype !== 'image/png') {
    throw new ValidationError('Formato no admitido: usa JPG o PNG');
  }
  return {
    buffer: file.buffer,
    filename: file.originalname,
    contentType: file.mimetype,
  };
}
