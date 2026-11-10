import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/course_participant.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_badges.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_table.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// PARTICIPANTES DE UN CURSO: /admin/cursos/:id/participantes
///
/// Lista los estudiantes inscritos en un curso con sus datos
/// esenciales (nombre, correo, fecha de inscripción, estado) y da
/// acceso a su perfil, desde donde el admin puede quitar el acceso.
class AdminCourseParticipantsScreen extends ConsumerStatefulWidget {
  const AdminCourseParticipantsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<AdminCourseParticipantsScreen> createState() =>
      _AdminCourseParticipantsScreenState();
}

class _AdminCourseParticipantsScreenState
    extends ConsumerState<AdminCourseParticipantsScreen> {
  /// Filtro por estado de la inscripción.
  String _status = 'all';

  bool _matches(CourseParticipant p) => switch (_status) {
    'access' => p.hasAccess,
    'pending' => p.status == 'pending_payment',
    'noaccess' => !p.hasAccess,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(participantsProvider(widget.courseId));

    return AdminPage(
      title: 'Participantes',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _LoadError(
          message: 'No se pudieron cargar los participantes: $error',
          onRetry: () => ref.invalidate(participantsProvider(widget.courseId)),
        ),
        data: (data) => AdminTableCard<CourseParticipant>(
          title: data.courseTitle,
          subtitle:
              '${data.participants.length} participante'
              '${data.participants.length == 1 ? '' : 's'}',
          items: data.participants.where(_matches).toList(),
          searchHint: 'Buscar por nombre o correo…',
          searchText: (p) => '${p.fullName} ${p.email}',
          emptyMessage: _status == 'all'
              ? 'Este curso aún no tiene participantes. Aparecerán aquí '
                    'en cuanto un estudiante se inscriba.'
              : 'Ningún participante coincide con el filtro seleccionado.',
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: () =>
                  ref.invalidate(participantsProvider(widget.courseId)),
              icon: const Icon(Icons.refresh),
            ),
          ],
          filters: [
            _chip('Todos', 'all'),
            _chip('Con acceso', 'access'),
            _chip('Pago en revisión', 'pending'),
            _chip('Sin acceso', 'noaccess'),
          ],
          columns: [
            AdminColumn<CourseParticipant>(
              label: 'Estudiante',
              width: 300,
              sortValue: (p) => p.fullName.toLowerCase(),
              cell: (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.fullName.isEmpty ? p.email : p.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    p.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AdminColumn<CourseParticipant>(
              label: 'Teléfono',
              sortValue: (p) => p.phone ?? '',
              cell: (p) => Text(p.phone ?? '—'),
            ),
            AdminColumn<CourseParticipant>(
              label: 'Inscripción',
              sortValue: (p) => p.enrolledAt ?? DateTime(2000),
              cell: (p) => Text(
                p.enrolledAt == null ? '—' : _formatDate(p.enrolledAt!),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            AdminColumn<CourseParticipant>(
              label: 'Estado',
              width: 180,
              sortValue: (p) => p.status,
              cell: (p) => enrollmentStatusBadge(p.status),
            ),
            AdminColumn<CourseParticipant>(
              label: 'Acciones',
              width: 110,
              isActions: true,
              cell: (p) => AdminActionButton(
                tooltip: 'Ver perfil',
                icon: Icons.person_outline,
                onPressed: () => _openProfile(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(CourseParticipant participant) {
    context.push('/admin/estudiantes/${participant.userId}');
  }

  Widget _chip(String label, String value) {
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

/// Error de carga + reintentar.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 38, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
