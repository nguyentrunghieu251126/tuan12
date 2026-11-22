String _two(int n) => n.toString().padLeft(2, '0');

String formatMoney(num value) {
  final digits = value.round().abs().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]}.',
      );
  return '${value < 0 ? '-' : ''}$digits đ';
}

String formatDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatShortDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
