import type { CatalogRepository, Category } from '../../domain/catalog.js';

/** Caso de uso: listar las categorías del catálogo (chips de filtro). */
export class ListCategories {
  constructor(private readonly catalog: CatalogRepository) {}

  execute(): Promise<Category[]> {
    return this.catalog.findAllCategories();
  }
}
