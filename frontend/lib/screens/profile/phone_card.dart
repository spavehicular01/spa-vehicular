import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Tarjeta del teléfono: al tocarla ofrece llamar o abrir WhatsApp.
class PhoneCard extends StatelessWidget {
  final String telefono;

  const PhoneCard({super.key, required this.telefono});

  Future<void> _hacerLlamada(String numero) async {
    final Uri url = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final String cleanNum = numero.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/57$cleanNum');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0x1A00E5FF),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.phone_android, color: AppColors.secondary),
        title: const Text('Número de Teléfono'),
        subtitle: Text(telefono),
        trailing: const Icon(Icons.touch_app, color: AppColors.secondary),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: AppColors.secondary),
                  title: const Text('Llamar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _hacerLlamada(telefono);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: const Text('WhatsApp'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirWhatsApp(telefono);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}