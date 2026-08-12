import 'package:flutter/material.dart';

/// Tela de manutenção — bloqueia completamente o aplicativo.
///
/// Exibida quando:
///   - maintenance = true no Firebase Remote Config
///
/// Casos de uso reais:
///   - Migração de banco de dados em andamento
///   - Deploy crítico do backend
///   - Instabilidade no servidor
///   - Atualização de infraestrutura (mudança de hosting, DNS, etc.)
///
/// Comportamento:
///   - Bloqueia completamente o app (WillPopScope → false)
///   - Sem botão de ação — o usuário aguarda
///   - Quando maintenance voltar a ser false no Remote Config,
///     o usuário precisa fechar e reabrir o app.
///
/// Melhoria futura:
///   - Adicionar polling (verificação periódica) para detectar
///     automaticamente quando a manutenção terminou e navegar
///     para a Home sem o usuário precisar reiniciar o app.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(84, 134, 135, 1),
                Color.fromRGBO(65, 110, 111, 1),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ─── Ícone ───
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.construction_rounded,
                          size: constraints.maxHeight * 0.08,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ─── Título ───
                      Text(
                        'Sistema em Manutenção',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxHeight * 0.032,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─── Descrição ───
                      Text(
                        'Estamos realizando melhorias no sistema.\n\n'
                        'O aplicativo estará disponível em breve.\n'
                        'Agradecemos pela sua paciência.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ─── Indicador de atividade ───
                      // Mostra ao usuário que algo está acontecendo
                      // e que o sistema não está travado.
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ─── Rodapé informativo ───
                      Text(
                        'Tente novamente em alguns minutos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
