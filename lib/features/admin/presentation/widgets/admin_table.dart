import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Decoración compartida de las tarjetas blancas del panel admin.
const adminCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ],
);

/// Botón de acción de fila (editar, desactivar…). Monocromo: icono
/// gris oscuro; [destructive] lo tiñe de rojo para desactivar.
class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String tooltip;
  final IconData icon;

  /// Null = botón deshabilitado (IconButton lo pinta atenuado).
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 19,
        color: destructive ? const Color(0xFFDC2626) : AppColors.textDark,
      ),
    );
  }
}

/// Definición de una columna de [AdminTableCard].
///
/// [cell] pinta la celda de cada fila y [sortValue] habilita el orden
/// ascendente/descendente al hacer clic en el encabezado.
class AdminColumn<T> {
  const AdminColumn({
    required this.label,
    required this.cell,
    this.width,
    this.sortValue,
    this.centered = false,
    this.isActions = false,
  });

  final String label;
  final Widget Function(T item) cell;

  /// Ancho fijo de la columna (si es null, se ajusta al contenido).
  final double? width;

  /// Valor comparable para ordenar; null = columna sin orden.
  final Comparable Function(T item)? sortValue;

  /// Centra el contenido de la celda.
  final bool centered;

  /// Columna de botones de acción: en vista de tarjetas (móvil) se
  /// renderiza al pie de la tarjeta en lugar de como fila label/valor.
  final bool isActions;
}

/// Tarjeta genérica de tabla administrativa: buscador, filtros,
/// orden por columna y paginación, con look consistente en todo el panel.
class AdminTableCard<T> extends StatefulWidget {
  const AdminTableCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.columns,
    required this.searchText,
    this.searchHint = 'Buscar…',
    this.filters = const [],
    this.actions = const [],
    this.emptyMessage = 'No hay registros para mostrar.',
    this.isLoading = false,
    this.rowsPerPage = 10,
    this.onRowTap,
  });

  final String title;
  final String? subtitle;

  /// Registros ya precargados; el filtrado/orden/paginación es local.
  final List<T> items;

  final List<AdminColumn<T>> columns;

  /// Texto de búsqueda de un registro (nombre + email + teléfono…).
  final String Function(T item) searchText;
  final String searchHint;

  /// Chips / dropdowns de filtro (los construye la pantalla).
  final List<Widget> filters;

  /// Botones de la esquina superior derecha (Nuevo…, recargar…).
  final List<Widget> actions;

  final String emptyMessage;
  final bool isLoading;
  final int rowsPerPage;
  final void Function(T item)? onRowTap;

  @override
  State<AdminTableCard<T>> createState() => _AdminTableCardState<T>();
}

class _AdminTableCardState<T> extends State<AdminTableCard<T>> {
  late final TextEditingController _search;
  String _query = '';
  int? _sortColumn;
  bool _ascending = true;
  int _page = 0;
  late int _rowsPerPage;

  static const _pageSizes = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _rowsPerPage = _pageSizes.contains(widget.rowsPerPage)
        ? widget.rowsPerPage
        : 10;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Registros filtrados por la búsqueda y ordenados por la columna activa.
  List<T> get _visible {
    final query = _query.trim().toLowerCase();
    final list = widget.items.where((item) {
      if (query.isEmpty) return true;
      return widget.searchText(item).toLowerCase().contains(query);
    }).toList();

    final columnIndex = _sortColumn;
    if (columnIndex != null && columnIndex < widget.columns.length) {
      final sortValue = widget.columns[columnIndex].sortValue;
      if (sortValue != null) {
        list.sort((a, b) {
          final cmp = sortValue(a).compareTo(sortValue(b));
          return _ascending ? cmp : -cmp;
        });
      }
    }
    return list;
  }

  void _toggleSort(int index) {
    setState(() {
      if (_sortColumn == index) {
        if (_ascending) {
          _ascending = false;
        } else {
          // Tercer clic: quita el orden.
          _sortColumn = null;
          _ascending = true;
        }
      } else {
        _sortColumn = index;
        _ascending = true;
      }
      _page = 0;
    });
  }

  /// Ancho de cada columna para que la tabla LLENE el ancho disponible:
  /// conserva los anchos fijos de [AdminColumn.width] y reparte el
  /// sobrante entre las columnas flexibles. Si el mínimo no cabe, la
  /// tabla desborda y el scroll horizontal se encarga (nunca rompe el
  /// layout): así la tabla ocupa todo el ancho de la tarjeta.
  List<double> _resolveColumnWidths(double availableWidth) {
    const margin = 16.0 * 2; // horizontalMargin del DataTable
    const spacing = 32.0; // columnSpacing
    const minWidth = 110.0; // ancho mínimo por columna flexible

    final columns = widget.columns;
    if (columns.isEmpty) return const [];

    final gaps = spacing * (columns.length - 1);
    final fixed = columns.fold<double>(0, (sum, c) => sum + (c.width ?? 0));
    final flexible = columns.where((c) => c.width == null).length;

    // Sin columnas flexibles: escala las fijas en proporción para que
    // el conjunto siga ocupando todo el ancho disponible.
    if (flexible == 0 && fixed > 0) {
      final usable = availableWidth - margin - gaps;
      if (usable > fixed) {
        final factor = usable / fixed;
        return [for (final c in columns) (c.width ?? 0) * factor];
      }
      return [for (final c in columns) c.width!.toDouble()];
    }

    final available = availableWidth - margin - gaps - fixed;
    final share = math.max(minWidth, available / flexible);
    return [for (final c in columns) c.width ?? share];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final pageCount = math.max(1, (visible.length / _rowsPerPage).ceil());
    final page = math.min(_page, pageCount - 1);
    final from = visible.isEmpty ? 0 : page * _rowsPerPage + 1;
    final to = math.min((page + 1) * _rowsPerPage, visible.length);

    return Container(
      decoration: adminCardDecoration,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: widget.title,
            subtitle: widget.subtitle,
            actions: widget.actions,
          ),
          const SizedBox(height: 16),
          _Toolbar(search: _searchField(), filters: widget.filters),
          const SizedBox(height: 6),
          if (widget.isLoading && widget.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visible.isEmpty)
            _EmptyState(
              message: _query.trim().isEmpty
                  ? widget.emptyMessage
                  : 'Ningún registro coincide con "${_query.trim()}".',
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                if (wide) {
                  final widths = _resolveColumnWidths(constraints.maxWidth);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _dataTable(visible, page, widths),
                  );
                }
                return _cardList(visible, page);
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Divider(height: 1),
            ),
            _PaginationBar(
              pageSizes: _pageSizes,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) => setState(() {
                _rowsPerPage = value;
                _page = 0;
              }),
              from: from,
              to: to,
              total: visible.length,
              page: page,
              pageCount: pageCount,
              onPrevious: () => setState(() => _page = page - 1),
              onNext: () => setState(() => _page = page + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchField() => TextField(
    controller: _search,
    onChanged: (value) => setState(() {
      _query = value;
      _page = 0;
    }),
    decoration: InputDecoration(
      isDense: true,
      hintText: widget.searchHint,
      prefixIcon: const Icon(Icons.search, size: 20),
      suffixIcon: _query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _search.clear();
                setState(() {
                  _query = '';
                  _page = 0;
                });
              },
            ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.black, width: 1.4),
      ),
    ),
  );

  Widget _dataTable(List<T> rows, int page, List<double> widths) {
    final start = page * _rowsPerPage;
    final pageRows = rows.skip(start).take(_rowsPerPage);

    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      dataRowMinHeight: 54,
      dataRowMaxHeight: 68,
      columnSpacing: 32,
      horizontalMargin: 16,
      showCheckboxColumn: false,
      columns: [
        for (var i = 0; i < widget.columns.length; i++)
          DataColumn(label: _header(i, widget.columns[i], widths[i])),
      ],
      rows: [
        for (final item in pageRows)
          DataRow(
            cells: [
              for (var i = 0; i < widget.columns.length; i++)
                _cell(item, widget.columns[i], widths[i]),
            ],
          ),
      ],
    );
  }

  /// Vista responsiva para pantallas angostas (< 640px): cada fila es
  /// una tarjeta con label/valor en lugar de una columna de la tabla.
  Widget _cardList(List<T> rows, int page) {
    final start = page * _rowsPerPage;
    final pageRows = rows.skip(start).take(_rowsPerPage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SortControl<T>(
          columns: widget.columns,
          sortColumn: _sortColumn,
          ascending: _ascending,
          onChanged: (index, ascending) => setState(() {
            _sortColumn = index;
            _ascending = ascending;
            _page = 0;
          }),
        ),
        const SizedBox(height: 10),
        for (final item in pageRows) _rowCard(item),
      ],
    );
  }

  Widget _rowCard(T item) {
    Widget content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna principal: se muestra completa sin label.
          widget.columns.first.cell(item),
          for (var i = 1; i < widget.columns.length; i++)
            if (!widget.columns[i].isActions) ...[
              const SizedBox(height: 8),
              _cardDetailRow(widget.columns[i], item),
            ],
          if (widget.columns.any((c) => c.isActions)) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final column in widget.columns)
                  if (column.isActions) column.cell(item),
              ],
            ),
          ],
        ],
      ),
    );

    final onTap = widget.onRowTap;
    if (onTap != null) {
      content = InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 10), child: content);
  }

  Widget _cardDetailRow(AdminColumn<T> column, T item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            column.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: column.centered
              ? Center(child: column.cell(item))
              : column.cell(item),
        ),
      ],
    );
  }

  Widget _header(int index, AdminColumn<T> column, double width) {
    final active = _sortColumn == index;
    final canSort = column.sortValue != null;
    const color = AppColors.textDark;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          column.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w900 : FontWeight.w800,
            color: color,
          ),
        ),
        if (canSort) ...[
          const SizedBox(width: 4),
          Icon(
            active
                ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 13,
            color: active ? AppColors.textDark : AppColors.textMuted,
          ),
        ],
      ],
    );

    return InkWell(
      onTap: canSort ? () => _toggleSort(index) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(width: width, child: label),
      ),
    );
  }

  DataCell _cell(T item, AdminColumn<T> column, double width) {
    Widget content = column.cell(item);
    content = SizedBox(width: width, child: content);
    if (column.centered) content = Center(child: content);

    return DataCell(
      content,
      onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(item),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        );
        final buttons = Wrap(spacing: 8, runSpacing: 8, children: actions);

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (actions.isNotEmpty) ...[const SizedBox(height: 12), buttons],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            buttons,
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.search, this.filters = const []});

  final Widget search;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final filterWrap = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: filters,
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              if (filters.isNotEmpty) ...[
                const SizedBox(height: 10),
                filterWrap,
              ],
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 280, child: search),
            const SizedBox(width: 12),
            Expanded(child: filterWrap),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Genérica en T para no leer `sortValue` (un closure con parámetro T)
/// a través de `AdminColumn<dynamic>`: en web eso lanza
/// "type '(T) => String' is not a subtype of '((dynamic) => Comparable)'"
/// por contravarianza de parámetros.
class _SortControl<T> extends StatelessWidget {
  const _SortControl({
    required this.columns,
    required this.sortColumn,
    required this.ascending,
    required this.onChanged,
  });

  final List<AdminColumn<T>> columns;
  final int? sortColumn;
  final bool ascending;
  final void Function(int? column, bool ascending) onChanged;

  @override
  Widget build(BuildContext context) {
    final sortable = <int>[];
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].sortValue != null) sortable.add(i);
    }
    if (sortable.isEmpty) return const SizedBox.shrink();

    final valid = sortColumn != null && sortable.contains(sortColumn);

    return Row(
      children: [
        const Icon(Icons.sort, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        DropdownButton<int>(
          value: valid ? sortColumn : null,
          hint: const Text(
            'Ordenar por…',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          isDense: true,
          underline: const SizedBox.shrink(),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          items: [
            for (final i in sortable)
              DropdownMenuItem(value: i, child: Text(columns[i].label)),
          ],
          onChanged: (i) => onChanged(i, ascending),
        ),
        IconButton(
          tooltip: ascending ? 'Descendente' : 'Ascendente',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              onChanged(valid ? sortColumn : sortable.first, !ascending),
          icon: Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageSizes,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.from,
    required this.to,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final List<int> pageSizes;
  final int rowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final int from;
  final int to;
  final int total;
  final int page;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final sizeSelector = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mostrar',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: rowsPerPage,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              items: [
                for (final size in pageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (value) {
                if (value != null) onRowsPerPageChanged(value);
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'por página',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        );
        final pager = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$from–$to de $total',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Anterior',
              visualDensity: VisualDensity.compact,
              onPressed: page > 0 ? onPrevious : null,
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
            Text(
              '${page + 1} / $pageCount',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            IconButton(
              tooltip: 'Siguiente',
              visualDensity: VisualDensity.compact,
              onPressed: page < pageCount - 1 ? onNext : null,
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ],
        );

        if (!wide) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [sizeSelector, const SizedBox(height: 4), pager],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [sizeSelector, const Spacer(), pager]),
        );
      },
    );
  }
}
