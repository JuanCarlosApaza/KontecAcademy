import type {
  AdminRepository,
  ImageUploadRecord,
} from '../../domain/admin.js';
import type { UploadImageDTO } from '../dtos/image_dto.js';

/** Caso de uso: subir la portada de un curso al bucket de Storage. */
export class UploadImage {
  constructor(
    private readonly admin: Pick<AdminRepository, 'uploadImage'>,
  ) {}

  execute(dto: UploadImageDTO): Promise<ImageUploadRecord> {
    return this.admin.uploadImage({
      buffer: dto.buffer,
      filename: dto.filename,
      contentType: dto.contentType,
    });
  }
}
