/// Utilitários de formatação compartilhados.

String _pad(int n) => n.toString().padLeft(2, '0');

/// Data curta: `dd/MM/yyyy`.
String formatarData(DateTime data) =>
    '${_pad(data.day)}/${_pad(data.month)}/${data.year}';

/// Data e hora: `dd/MM/yyyy às HH:mm`.
String formatarDataHora(DateTime data) =>
    '${formatarData(data)} às ${_pad(data.hour)}:${_pad(data.minute)}';
