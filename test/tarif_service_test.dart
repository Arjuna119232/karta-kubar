import 'package:flutter_test/flutter_test.dart';
import 'package:kubar_connect/shared/services/tarif_service.dart';

void main() {
  const TarifService t = TarifService();

  test('tarif ojek per tingkat jarak', () {
    expect(t.tarifOjek(0), 7000);
    expect(t.tarifOjek(2), 7000);
    expect(t.tarifOjek(2.01), 10000);
    expect(t.tarifOjek(4), 10000);
    expect(t.tarifOjek(6), 14000);
    expect(t.tarifOjek(8), 18000);
    expect(t.tarifOjek(10), 22000);
    expect(t.tarifOjek(12), 26000);
    expect(t.tarifOjek(15), 32000);
    expect(t.tarifOjek(16), 34500);
    expect(t.tarifOjek(20), 44500);
  });

  test('fee antar jastip per tingkat jarak', () {
    expect(t.feeJastip(0.5), 3000);
    expect(t.feeJastip(1), 3000);
    expect(t.feeJastip(1.5), 5000);
    expect(t.feeJastip(3), 7000);
    expect(t.feeJastip(4), 9000);
    expect(t.feeJastip(5), 11000);
    expect(t.feeJastip(7), 15000);
    expect(t.feeJastip(10), 20000);
    expect(t.feeJastip(12), 25000);
    expect(t.feeJastip(14), 30000);
  });
}
