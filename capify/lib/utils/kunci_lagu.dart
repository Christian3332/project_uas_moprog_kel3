import '../models/lagu.dart';

String kunciUnikLagu(Lagu lagu) =>
    '${lagu.judul}|${lagu.penyanyi}'.toLowerCase();
