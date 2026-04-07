import 'package:flutter/material.dart';
import '../../../../../core/di/injection_container.dart';
import '../../data/repositories/auth_repository.dart';
import '../controller/session_controller.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController(); // 📱 Novo Controller
  bool _carregando = false;

  Future<void> _salvar() async {
    // Validação básica
    if (_nomeController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _telefoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    setState(() => _carregando = true);
    final session = sl<SessionController>();

    try {
      // Chamada atualizada com o campo 'phone'
      await sl<AuthRepository>().cadastrarNovoUsuario(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        phone: _telefoneController.text.trim(), // 📱 Enviando o telefone
        senha: "123456", 
        role: "operador", 
        companyId: session.usuario!.companyId, 
      );

      if (mounted) {
        Navigator.pop(context);
        // Opcional: Mostrar aviso que agora pode enviar pelo Whats na tela anterior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Operador criado! Use o ícone de chat para enviar o acesso."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Novo Operador"),
      content: SingleChildScrollView( // Adicionado para evitar erro de layout com teclado
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController, 
              decoration: const InputDecoration(
                labelText: "Nome Completo",
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(
                labelText: "E-mail",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telefoneController, 
              decoration: const InputDecoration(
                labelText: "Telefone (com DDD)",
                hintText: "Ex: 5541999999999",
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
              // Dica: Se quiser formatar enquanto digita, use o pacote 'mask_text_input_formatter'
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Senha inicial padrão: 123456",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _carregando ? null : () => Navigator.pop(context), 
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _carregando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          child: _carregando 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text("CRIAR E SALVAR"),
        ),
      ],
    );
  }
}