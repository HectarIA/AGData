import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/di/injection_container.dart';
import '../controller/session_controller.dart';
import '../../../auth/data/models/auth_model.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionController _session = sl<SessionController>();
  
  final _nomeEmpresaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nomeAdminController = TextEditingController();
  final _cpfAdminController = TextEditingController();
  final _senhaAdminController = TextEditingController();

  bool _carregando = false;
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cnpjFormatter = MaskTextInputFormatter(mask: '##.###.###/####-##');

  Future<void> _cadastrarTudo() async {
    // 🛡️ TRAVA DE SEGURANÇA MESTRE
    if (_session.usuario?.role != UserRole.superAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Apenas o Desenvolvedor pode criar empresas.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      final String cleanCpf = _cpfAdminController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final String emailSintetico = '$cleanCpf@hectaria.com.br';

      DocumentReference empresaRef = FirebaseFirestore.instance.collection('companies').doc();
      
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailSintetico,
        password: _senhaAdminController.text,
      );

      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.set(empresaRef, {
        'name': _nomeEmpresaController.text,
        'cnpj': _cnpjController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid), {
        'uid': userCred.user!.uid,
        'name': _nomeAdminController.text,
        'cpf': cleanCpf,
        'companyId': empresaRef.id,
        'role': UserRole.admin.name, 
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso! Empresa e Admin criados.'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _nomeEmpresaController.clear();
        _cnpjController.clear();
        _nomeAdminController.clear();
        _cpfAdminController.clear();
        _senhaAdminController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel HectarIA - Global'),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('CADASTRO DE NOVA FAZENDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nomeEmpresaController,
                    decoration: const InputDecoration(labelText: 'Nome da Fazenda', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cnpjController,
                    inputFormatters: [_cnpjFormatter],
                    decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const Divider(height: 40),
                  const Text('ADMINISTRADOR DA FAZENDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nomeAdminController,
                    decoration: const InputDecoration(labelText: 'Nome do Admin', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _cpfAdminController,
                    inputFormatters: [_cpfFormatter],
                    decoration: const InputDecoration(labelText: 'CPF (Login)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.length < 14 ? 'CPF Inválido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _senhaAdminController,
                    decoration: const InputDecoration(labelText: 'Senha Inicial', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _carregando ? null : _cadastrarTudo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _carregando 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('CADASTRAR EMPRESA E ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Align(alignment: Alignment.centerLeft, child: Text('EMPRESAS CADASTRADAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            
            // LISTA DE EMPRESAS EM TEMPO REAL
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.business, color: Colors.green),
                        title: Text(data['name'] ?? 'Sem nome'),
                        subtitle: Text('CNPJ: ${data['cnpj'] ?? 'N/A'}'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}