/// Formato de dinero en dólares (USD).
library;

/// 1490 → '\$1490.00' (fuente única del formato de precios en la UI).
///
/// Sin separador de miles y con 2 decimales: el mismo formato se usa en
/// tarjetas, detalle, carrito, checkout y panel admin para que un precio
/// nunca se vea distinto en dos pantallas.
String formatDollars(double amount) => '\$${amount.toStringAsFixed(2)}';
