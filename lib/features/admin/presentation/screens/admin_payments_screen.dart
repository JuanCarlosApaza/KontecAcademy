import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../admin_injector.dart';
import '../../domain/entities/abandoned_cart_item.dart';
import '../../domain/entities/payment_record.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Etiqueta de estado de pago: pendiente (ámbar), aprobado (verde),
/// rechazado (rojo).
Widget _paymentStatusBadge(String status) {
  final (label, background, icon, iconColor) = switch (status) {
    'approved' => (
      'Aprobado',
      const Color(0xFFECFDF5),
      Icons.check_circle_outline,
      const Color(0xFF059669),
    ),
    'rejected' => (
      'Rechazado',
      const Color(0xFFFEF2F2),
      Icons.cancel_outlined,
      const Color(0xFFDC2626),
    ),
    _ => (
      'Por aprobar',
      const Color(0xFFFFFBEB),
      Icons.schedule,
      const Color(0xFFD97706),
    ),
  };

  return AdminBadge(
    label: label,
    background: background,
    icon: icon,
    iconColor: iconColor,
  );
}

/// PAGOS Y CARRITOS: /admin/pagos
///
/// Diagnóstico de ventas incompletas (estilo WooCommerce):
///  * "Pagos por aprobar": quien llegó a checkout y subió el ticket,
///    con el filtro de estado (por defecto la cola de pendientes).
///  * "Carritos abandonados": quién agregó cursos al carrito pero
///    NUNCA completó el checkout (queda registrado en el servidor).
class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  /// Estado del filtro de pagos: pending_approval | approved | rejected.
  String _status = 'pending_approval';

  /// Id del pago que se está decidiendo (para deshabilitar los botones).
  String? _decidingId;

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider(_status));
    final cartsAsync = ref.watch(abandonedCartsProvider);

    final payments = paymentsAsync.value ?? const [];
    final carts = cartsAsync.value ?? const [];

    return AdminPage(
      title: 'Pagos y carritos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTableCard<PaymentRecord>(
            title: 'Pagos por aprobar',
            subtitle:
                'Llegaron a checkout y registraron un pago; esperan '
                'tu aprobación.',
            isLoading: paymentsAsync.isLoading && payments.isEmpty,
            items: payments,
            searchHint: 'Buscar por estudiante, email o curso…',
            searchText: (p) => '${p.fullName} ${p.email} ${p.courseTitle}',
            emptyMessage: _status == 'pending_approval'
                ? 'No hay pagos esperando aprobación. ¡Buen trabajo! 🎉'
                : 'No hay pagos con este estado.',
            actions: [
              IconButton(
                tooltip: 'Recargar',
                onPressed: paymentsAsync.isLoading
                    ? null
                    : () => ref.invalidate(paymentsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
            filters: [
              _statusChip('Por aprobar', 'pending_approval'),
              _statusChip('Aprobados', 'approved'),
              _statusChip('Rechazados', 'rejected'),
            ],
            columns: [
              AdminColumn<PaymentRecord>(
                label: 'Estudiante',
                width: 260,
                sortValue: (p) => p.fullName.toLowerCase(),
                cell: (p) => _userCell(p.fullName, p.email),
              ),
              AdminColumn<PaymentRecord>(
                label: 'Curso',
                sortValue: (p) =>
                    (p.pathTitle ?? p.courseTitle).toLowerCase(),
                cell: (p) => Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      p.pathTitle != null
                          ? 'Ruta: ${p.pathTitle}'
                          : p.courseTitle,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (p.isPath)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Combo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AdminColumn<PaymentRecord>(
                label: 'Monto',
                width: 120,
                sortValue: (p) => p.amount,
                cell: (p) => Text(
                  formatDollars(p.amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              AdminColumn<PaymentRecord>(
                label: 'Estado',
                width: 130,
                sortValue: (p) => p.status,
                cell: (p) => _paymentStatusBadge(p.status),
              ),
              AdminColumn<PaymentRecord>(
                label: 'Fecha',
                width: 110,
                sortValue: (p) => p.createdAt ?? DateTime(2000),
                cell: (p) => Text(
                  p.createdAt == null ? '—' : _formatDate(p.createdAt!),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              AdminColumn<PaymentRecord>(
                label: 'Acciones',
                width: 120,
                isActions: true,
                cell: (p) => _paymentActions(p),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AdminTableCard<AbandonedCartItem>(
            title: 'Carritos abandonados',
            subtitle:
                'Agregaron cursos al carrito pero nunca completaron el '
                'checkout (${carts.length} en total).',
            isLoading: cartsAsync.isLoading && carts.isEmpty,
            items: carts,
            searchHint: 'Buscar por estudiante, email o curso…',
            searchText: (c) => '${c.fullName} ${c.email} ${c.title}',
            emptyMessage:
                'Ningún usuario tiene cursos en el carrito sin pagar.',
            actions: [
              IconButton(
                tooltip: 'Recargar',
                onPressed: cartsAsync.isLoading
                    ? null
                    : () => ref.invalidate(abandonedCartsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
            columns: [
              AdminColumn<AbandonedCartItem>(
                label: 'Estudiante',
                width: 260,
                sortValue: (c) => c.fullName.toLowerCase(),
                cell: (c) => _userCell(c.fullName, c.email),
              ),
              AdminColumn<AbandonedCartItem>(
                label: 'Curso',
                sortValue: (c) => c.title.toLowerCase(),
                cell: (c) =>
                    Text(c.title, style: const TextStyle(fontSize: 13)),
              ),
              AdminColumn<AbandonedCartItem>(
                label: 'Precio',
                width: 120,
                sortValue: (c) => c.price,
                cell: (c) => Text(
                  formatDollars(c.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              AdminColumn<AbandonedCartItem>(
                label: 'Agregado',
                width: 110,
                sortValue: (c) => c.addedAt ?? DateTime(2000),
                cell: (c) => Text(
                  c.addedAt == null ? '—' : _formatDate(c.addedAt!),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Botones Aprobar/Rechazar (solo en pagos todavía pendientes).
  Widget _paymentActions(PaymentRecord payment) {
    if (!payment.isPending) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    // Ver el pago no es decidirlo: sin payments:approve solo se lee.
    if (!ref.watch(permissionProvider('payments:approve'))) {
      return const Text(
        'Solo lectura',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }

    if (_decidingId == payment.id) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final locked = _decidingId != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Aprobar (dar acceso al curso)',
          visualDensity: VisualDensity.compact,
          onPressed: locked ? null : () => _decide(payment, approve: true),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF059669),
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Rechazar (sin acceso)',
          visualDensity: VisualDensity.compact,
          onPressed: locked ? null : () => _decide(payment, approve: false),
          icon: const Icon(
            Icons.cancel_outlined,
            color: Color(0xFFDC2626),
            size: 20,
          ),
        ),
      ],
    );
  }

  /// Confirmación + llamada al backend (`PATCH /admin/payments/:id`).
  /// Al aprobar, la inscripción pasa a 'approved': el estudiante ya
  /// ve el curso en "Mis cursos" con acceso. Se recarga la tabla y el
  /// KPI de pendientes del dashboard.
  Future<void> _decide(PaymentRecord payment, {required bool approve}) async {
    // Combo (ruta): el ticket aprueba TODOS los cursos de la ruta.
    final target = payment.pathTitle != null
        ? 'la ruta "${payment.pathTitle}" con TODOS sus cursos'
        : '"${payment.courseTitle}"';

    final confirmed = await showConfirmDialog(
      context: context,
      title: approve ? '¿Aprobar este pago?' : '¿Rechazar este pago?',
      message: approve
          ? '${payment.fullName} obtendrá ACCESO a $target '
                '(${formatDollars(payment.amount)}). Verificado manualmente '
                'por ti.'
          : '${payment.fullName} quedará SIN ACCESO a '
                '$target. Puedes aprobarlo más tarde '
                'desde el filtro de pendientes.',
      confirmLabel: approve ? 'Aprobar' : 'Rechazar',
      icon: approve ? Icons.verified_outlined : Icons.cancel_outlined,
    );
    if (!confirmed) return;

    setState(() => _decidingId = payment.id);
    final (ok, failure) = await ref.read(decidePaymentProvider)(
      DecidePaymentParams(paymentId: payment.id, approve: approve),
    );
    if (!mounted) return;
    setState(() => _decidingId = null);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure?.message ?? 'No se pudo actualizar el pago.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    ref.invalidate(paymentsProvider);
    ref.invalidate(adminViewModelProvider); // KPI de pendientes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Pago aprobado: ${payment.fullName} ya tiene acceso al curso.'
              : 'Pago rechazado: ${payment.fullName} quedó sin acceso.',
        ),
      ),
    );
  }

  /// Nombre + email del estudiante (misma celda que en Estudiantes).
  Widget _userCell(String fullName, String email) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        fullName.isEmpty ? email : fullName,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      if (fullName.isNotEmpty)
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
    ],
  );

  Widget _statusChip(String label, String value) {
    final selected = _status == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.black,
      side: BorderSide(
        color: selected ? AppColors.black : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textMuted,
      ),
      onSelected: (_) => setState(() => _status = value),
    );
  }
}
