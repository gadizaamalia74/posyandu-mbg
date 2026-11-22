import 'package:flutter/material.dart';

import 'format.dart';
import 'theme.dart';

void showMsg(BuildContext context, String msg, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: error ? C.badFg : C.okFg, fontWeight: FontWeight.w600)),
      backgroundColor: error ? C.badBg : C.okBg,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmDialog(BuildContext context, String text) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: C.danger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ya'),
        ),
      ],
    ),
  );
  return r ?? false;
}

class PageTitle extends StatelessWidget {
  final String text;
  final bool center;
  const PageTitle(this.text, {super.key, this.center = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.navy)),
      );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? color;
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x1A0D2D4A), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

class AlertBox extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const AlertBox(this.text, {super.key, this.bg = C.infoBg, this.fg = C.infoFg});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 14)),
      );
}

/// Label di atas, input di bawah (gaya .form-label + .form-control).
class Field extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure, readOnly;
  final TextInputType? keyboard;
  final int maxLines;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  const Field(
    this.label, {
    super.key,
    this.controller,
    this.hint,
    this.obscure = false,
    this.readOnly = false,
    this.keyboard,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          TextField(
            controller: controller,
            obscureText: obscure,
            readOnly: readOnly,
            keyboardType: keyboard,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              fillColor: readOnly ? const Color(0xFFF0F4F8) : Colors.white,
            ),
          ),
        ]),
      );
}

/// Input tanggal dengan date picker (nilai YYYY-MM-DD).
class DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  const DateField(this.label, this.controller, {super.key, this.readOnly = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          TextField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: C.navy),
            ),
            onTap: readOnly
                ? null
                : () async {
                    final init = parseDate(controller.text) ?? DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: init,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) controller.text = isoDate(d);
                  },
          ),
        ]),
      );
}

class TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const TimeField(this.label, this.controller, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          TextField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: 'HH:MM',
              suffixIcon: Icon(Icons.access_time, size: 18, color: C.navy),
            ),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
              if (t != null) {
                controller.text =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              }
            },
          ),
        ]),
      );
}

class Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const Dropdown(this.label, {super.key, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          DropdownButtonFormField<T>(
            // ignore: deprecated_member_use
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ]),
      );
}

enum BtnKind { primary, secondary, outline, danger }

class Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool big;
  final bool loading;
  const Btn(this.text,
      {super.key, this.onPressed, this.kind = BtnKind.primary, this.big = false, this.loading = false});
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      BtnKind.primary => (C.navy, Colors.white),
      BtnKind.secondary => (C.blueLight, C.navy),
      BtnKind.danger => (C.danger, Colors.white),
      BtnKind.outline => (Colors.transparent, C.navy),
    };
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size(big ? double.infinity : 0, big ? 50 : 40),
        padding: EdgeInsets.symmetric(horizontal: big ? 24 : 18, vertical: big ? 14 : 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(big ? 10 : 8),
          side: kind == BtnKind.outline ? const BorderSide(color: C.border, width: 1.5) : BorderSide.none,
        ),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: big ? 15 : 13.5, letterSpacing: .3),
      ),
      child: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(text),
    );
  }
}

class Badge2 extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Badge2(this.text, this.bg, this.fg, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

/// Tabel dengan header navy (gaya table di style.css). Baris bisa dipilih.
class AppTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final String empty;
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.selected,
    this.onSelect,
    this.empty = 'Belum ada data',
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text(empty, style: const TextStyle(color: Colors.black45))),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: const WidgetStatePropertyAll(C.navy),
                headingTextStyle:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                dataTextStyle: const TextStyle(color: C.navy, fontSize: 13),
                columnSpacing: 22,
                horizontalMargin: 16,
                dataRowMinHeight: 44,
                columns: [for (final c in columns) DataColumn(label: Text(c))],
                rows: [
                  for (var i = 0; i < rows.length; i++)
                    DataRow(
                      selected: selected == i,
                      color: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected) ? const Color(0xFFDBEEF8) : null),
                      onSelectChanged: onSelect == null ? null : (_) => onSelect!(i),
                      cells: [for (final c in rows[i]) DataCell(Text(c))],
                    ),
                ],
              ),
            ),
    );
  }
}

/// Kolom pencarian (gaya .search-bar).
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSearch;
  const SearchBox(this.controller, {super.key, required this.hint, required this.onSearch});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Btn('Cari', onPressed: onSearch),
        ]),
      );
}

/// Pembungkus pemuatan data async dengan loading + error + tombol coba lagi.
class Loader<T> extends StatelessWidget {
  final Future<T>? future;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  const Loader({super.key, required this.future, required this.builder, this.onRetry});
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError) {
            return CardBox(
              child: Column(children: [
                Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: C.badFg)),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  Btn('Coba lagi', onPressed: onRetry, kind: BtnKind.secondary),
                ],
              ]),
            );
          }
          return builder(snap.data as T);
        },
      );
}
