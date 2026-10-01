import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Campo de observações do relatório com ditado por voz **offline**.
///
/// Usa o motor nativo de reconhecimento (Android SpeechRecognizer / iOS Speech)
/// em modo on-device, transcrevendo a fala diretamente no campo de texto.
class ObservacaoField extends StatefulWidget {
  final TextEditingController controller;
  const ObservacaoField({super.key, required this.controller});

  @override
  State<ObservacaoField> createState() => _ObservacaoFieldState();
}

class _ObservacaoFieldState extends State<ObservacaoField> {
  final SpeechToText _speech = SpeechToText();
  bool _disponivel = false;
  bool _ouvindo = false;

  /// Texto já existente antes de iniciar o ditado (para concatenar).
  String _base = '';

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _alternarMicrofone() async {
    if (_ouvindo) {
      await _speech.stop();
      if (mounted) setState(() => _ouvindo = false);
      return;
    }

    if (!_disponivel) {
      _disponivel = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _ouvindo = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _ouvindo = false);
        },
      );
    }

    if (!_disponivel) {
      _avisar('Reconhecimento de voz indisponível neste dispositivo.');
      return;
    }

    _base = widget.controller.text.trim();
    setState(() => _ouvindo = true);

    await _speech.listen(
      onResult: (resultado) {
        final sep = _base.isEmpty ? '' : '$_base ';
        widget.controller.text = '$sep${resultado.recognizedWords}';
        widget.controller.selection = TextSelection.collapsed(
            offset: widget.controller.text.length);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'pt_BR',
        onDevice: true,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  void _avisar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Observações',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (_ouvindo)
              Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      color: AppColors.danger, size: 12),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Ouvindo...',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.danger)),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Adicione observações ou toque no microfone para ditar...',
            alignLabelWithHint: true,
            suffixIcon: IconButton(
              icon: Icon(
                _ouvindo ? Icons.stop_circle : Icons.mic_none,
                color: _ouvindo ? AppColors.danger : AppColors.primary,
                size: 28,
              ),
              tooltip: _ouvindo ? 'Parar ditado' : 'Ditar por voz',
              onPressed: _alternarMicrofone,
            ),
          ),
        ),
      ],
    );
  }
}
