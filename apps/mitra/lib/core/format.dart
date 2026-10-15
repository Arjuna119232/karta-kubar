import 'package:intl/intl.dart';

final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
String rp(num v) => _rp.format(v);
String jam(DateTime d) => DateFormat('dd MMM, HH:mm').format(d.toLocal());
