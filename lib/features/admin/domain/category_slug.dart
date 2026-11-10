/// Regla de negocio única: el slug de una categoría se genera a partir
/// de su nombre si no viene indicado. "Geotecnia y Vías" →
/// "geotecnia-y-vías". (Vive en el dominio: la usan los casos de uso
/// CreateCategory y UpdateCategory.)
String categorySlug(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

/// Slug efectivo: usa el indicado si viene; si no, lo deriva del nombre.
String categorySlugFor(String name, String slug) =>
    slug.trim().isEmpty ? categorySlug(name) : slug.trim();
