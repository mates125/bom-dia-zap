import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'collections_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _api = ApiService();
  bool _isTogglingPremium = false;

  Future<void> _toggleDevPremium() async {
    setState(() => _isTogglingPremium = true);
    try {
      await _api.toggleDevPremium();
      await authService.fetchMe();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alternar o modo teste.')),
      );
    } finally {
      if (mounted) setState(() => _isTogglingPremium = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.email),
            subtitle: Text(user.isPremium ? 'Conta premium' : 'Conta gratuita'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.collections_bookmark_rounded),
            title: const Text('Minhas coleções'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CollectionsScreen()),
              );
            },
          ),
          const Divider(),
          // TEMPORÁRIO: só pra testar recursos premium antes do Google Play
          // Billing existir de verdade. Remover quando a compra estiver pronta.
          SwitchListTile(
            secondary: const Icon(Icons.science_outlined),
            title: const Text('Modo premium (teste)'),
            subtitle: const Text('Temporário, até a compra de verdade existir'),
            value: user.isPremium,
            onChanged: _isTogglingPremium ? null : (_) => _toggleDevPremium(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sair'),
            onTap: () async {
              await authService.logout();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
