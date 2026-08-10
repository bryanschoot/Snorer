import '../models/recording.dart';

String formatDuration(double totalSeconds) {
  final safeSeconds = totalSeconds.isFinite ? totalSeconds : 0;
  final seconds = safeSeconds.round().clamp(0, 863999).toInt();
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;

  if (hours > 0) {
    return '${hours}u ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes}m ${remainder.toString().padLeft(2, '0')}s';
}

String formatClock(double totalSeconds) {
  final safeSeconds = totalSeconds.isFinite ? totalSeconds : 0;
  final seconds = safeSeconds.floor().clamp(0, 863999).toInt();
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}

String formatDate(DateTime value) {
  const months = <String>[
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];
  final local = value.toLocal();
  final month = months[local.month - 1];
  return '${local.day} $month · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}


String eventCountText(SoundEventKind kind, int count) {
  final noun = kind == SoundEventKind.snoring ? 'snurkmoment' : 'praatmoment';
  return '$count $noun${count == 1 ? '' : 'en'}';
}
