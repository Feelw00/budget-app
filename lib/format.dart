import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _won = NumberFormat.decimalPattern('ko');

String krw(num n) {
  final v = n.round();
  return '${v < 0 ? '-' : ''}₩${_won.format(v.abs())}';
}

String signed(String type, num n) => (type == 'income' ? '+' : '-') + krw(n);

const Color incomeColor = Color(0xFF2563EB);
const Color expenseColor = Color(0xFFDC2626);

Color amountColor(num n) => n < 0 ? expenseColor : const Color(0xFF1F2430);

String typeLabel(String t) => t == 'income' ? '수입' : '지출';
String methodLabel(String m) => const {'cash': '현금', 'card': '카드', 'transfer': '이체'}[m] ?? m;

String todayStr() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
