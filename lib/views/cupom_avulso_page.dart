import 'dart:async';
import 'dart:convert';
import 'dart:math' as math show max;

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/widgets/side_nav.dart';

class CupomAvulsoPage extends StatefulWidget {
  const CupomAvulsoPage({super.key});

  @override
  State<CupomAvulsoPage> createState() => _CupomAvulsoPageState();
}

class _CupomAvulsoPageState extends State<CupomAvulsoPage> {

  final FuncoesController funcoesController = Get.put(FuncoesController());
  String versaoAplicacao = FuncoesController().versaoDoApp;

  final TextEditingController textoCupomAvulsoController = TextEditingController();
  final FocusNode textoCupomAvulsoFocusNode = FocusNode();

  bool aparecerNote = false;
  bool aparecerCupomAvulso = false;
  bool aparecerRecepcao = false;
  bool aparecerGarcom = false;
  bool naoAparecerMapa = false;
  bool aparecerCheckInOut = false;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;

  String nomeEmpresa = "";
  String numeroDaLicencaSelecionada = "";

  late Timer _timer;
  String _horaAtual = "";

  RxString nomeImpressoraSelecionada = ''.obs;
  RxString numeroImpressoraSelecionada = ''.obs;

  RxList<dynamic> impressorasSelecionadas = <dynamic>[].obs;

  bool isLoading = false;

  String documento = "";

  @override
  void initState() {
    super.initState();
    carregarConfiguracoes();
    _atualizarHora();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _atualizarHora();
    });
  }

  void carregarConfiguracoes() async {
    await _carregarNote();
    await _carregarCupomAvulso();
    await _carregarRecepcao();
    await _carregargarcom();
    await _carregarModos();
    await _carregarchecks();
    await _loadNomeEmpresa();
    await _loadNumeroLicenca();
  }

/*  String gerarDocumento(String texto, String colunasFuncao) {
  String gerandoDocumento = '''
<2>     CUPOM AVULSO
<0>
<0>$texto
<0>
<0>
<0>------------------------------------------------
<0>    UN Gourmet | PedeAqu!.app | Etiqueta.Ai
<0>------------------------------------------------
<0>
<0>
''';

  documento = gerandoDocumento;
  return documento;
} */
  String gerarDocumento(String texto, String colunasFuncao) {
    int larguraCupom = int.parse(colunasFuncao);
    int larguraCupom2 = int.parse(colunasFuncao) ~/ 2;

    String centralizar(String texto) {
      if (texto.length >= larguraCupom) {
        return texto.substring(0, larguraCupom);
      }

      final int espacos = (larguraCupom - texto.length) ~/ 2;

      return '${' ' * espacos}$texto';
    }

    String centralizarTamanho2(String texto) {
      if (texto.length >= larguraCupom2) {
        return texto.substring(0, larguraCupom2);
      }

      final int espacos = ((larguraCupom2 - texto.length) ~/ 2);

      return '${' ' * espacos}$texto';
    }

    String linha = '-' * larguraCupom;

    String hashtag = '*' * larguraCupom;

    String gerarLinhaTexto(String texto) {
      if (texto.length <= larguraCupom) {
        return texto;
      }

      final List<String> partes = [];

      for (int i = 0; i < texto.length; i += larguraCupom) {
        final int fim = (i + larguraCupom < texto.length)
            ? i + larguraCupom
            : texto.length;

        partes.add(texto.substring(i, fim));
      }

      return partes.join('\n<0>');
    }

    String gerarTexto(String texto) {
      final List<String> partes = [];

      for (int i = 0; i < texto.length; i += larguraCupom) {
        final int fim = (i + larguraCupom < texto.length)
            ? i + larguraCupom
            : texto.length;

        final String parte = texto.substring(i, fim);

        partes.add(centralizar(parte));
      }

      return partes.join('\n<5>');
    }

    final String gerandoDocumento = '''
<0>$linha
<2>${centralizarTamanho2('#CUPOM AVULSO#')}
<0>$linha
<0>
<5>${gerarTexto(texto)}
<0>
<0>$linha
<0>${centralizar('UN Gourmet | PedeAqu!.app | Etiqueta.ai')}
<0>$linha
<0>
<0>
''';

    documento = gerandoDocumento;
    return documento;
  }

  void limparPage(){
    textoCupomAvulsoController.clear();
    impressorasSelecionadas.clear();
  }

  Future<void> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null && mounted) {
      setState(() {
        numeroDaLicencaSelecionada = licencaSalvoNumero;
      });
    }
  }

  // Carregar check
  Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Check-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-out") &&
          !checksSalvos.contains("Check-in")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
        });
      } else if (!checksSalvos.contains("Check-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-in") &&
          checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      } else {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = false;
        aparecerCheckOut = false;
      });
    }
  }

  // Carregar modo
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
        // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
        naoAparecerMapa = !(modosSalvos.contains("Mesa") || modosSalvos.contains("Comanda"));

        // Lógica de aparecerCheckInOut baseada nos modos Comanda/Mesa
        if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = false;
        } else if (modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = true;
        } else {
          aparecerCheckInOut = false;
        }
      });
    } else {
      setState(() {
        // Se não existir configuração salva (primeira execução), mapa deve vir DESABILITADO
        naoAparecerMapa = true;
        aparecerCheckInOut = true; // Mantendo o padrão deste arquivo
      });
    }
  }

  // Carregar garçom
  Future<void> _carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));

      if (garcomSalvos.contains("Modo Garçom")) {
        setState(() {
          aparecerGarcom = true;
        });
      } else if (!garcomSalvos.contains("Modo Garçom")) {
        setState(() {
          aparecerGarcom = false;
        });
      } else {
        setState(() {
          aparecerGarcom = true;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerGarcom = true;
      });
    }
  }

  // Carregar recepcao
  Future<void> _carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('Recepção')) {
        // se recepcao selecionado
        setState(() {
          aparecerRecepcao = true;
        });
      } else {
        // se recepcao nao selecionado
        setState(() {
          aparecerRecepcao = false;
        });
      }
    } else {
      // configuração padrao
      setState(() {
        aparecerRecepcao = false;
      });
    }
  }

  // Carregar cupom avulso
  Future<void> _carregarCupomAvulso() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('cupom_avulso');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('Cupom Avulso')) {
        // se cupom avulso selecionado
        setState(() {
          aparecerCupomAvulso = true;
        });
      } else {
        // se cupom avulso nao selecionado
        setState(() {
          aparecerCupomAvulso = false;
        });
      }
    } else {
      // configuração padrao
      setState(() {
        aparecerCupomAvulso = false;
      });
    }
  }

  // Carregar note
  Future<void> _carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('Notes')) {
        // se note selecionado
        setState(() {
          aparecerNote = true;
        });
      } else {
        // se note nao selecionado
        setState(() {
          aparecerNote = false;
        });
      }
    } else {
      // configuração padrao
      setState(() {
        aparecerNote = false;
      });
    }
  }

  // Load nomeEmpresa
  Future<void> _loadNomeEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeEmpresaSalvo = prefs.getString('nomeEmpresa');
    if (nomeEmpresaSalvo != null) {
      setState(() {
        nomeEmpresa = nomeEmpresaSalvo;
      });
    }
  }

  // Função para atualizar hora
  void _atualizarHora() {
    if (!mounted) return;
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
    });
  }

  // Função para inserir um novo registro de impressão
  Future<void> inserirServidorImpressao(
    String numeroTradepoint,
    String numeroImpressora,
    String documento,
    String colunas
  ) async {
    try {
      String sql = """
        INSERT INTO servidorimpressao (
          numerotradepoint_FK,
          numeroimpressora_FK,
          documento,
          tipodocumento,
          comando,
          datahoraenvio
        ) VALUES (
          '$numeroTradepoint',
          '$numeroImpressora',
          '$documento',
          '1',
          '1',
          CURRENT_TIMESTAMP
        )
      """;

      // Executa o SQL
      String idServidorImpressao = await Connection().insertId(sql);

      print("Id servidorimpressao retornado: $idServidorImpressao");
    } catch (e) {
      print("Erro inesperado ao inserir servidorimpressao: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          // este Obx cuida APENAS do que realmente depende de conexão
          final conectado = Connection.connectionStatus.value;
          return AppBar(
            backgroundColor: conectado
                ? colorScheme.primary
                : colorScheme.error,
            automaticallyImplyLeading: false,
            title: Stack(
              alignment: Alignment.center,
              children: [
                // MENU
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Image.asset(
                        'assets/logo_branco2.png',
                        width: 30,
                        // 24
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),

                // CENTRO - Nome && Hora
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nomeEmpresa,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),

                      Text(
                        _horaAtual,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS - precisa de Obx
                Align(
                  alignment: Alignment.centerRight,
                  child: 
                  Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Text(
                          Connection.connectionStatus.value ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "$versaoAplicacao",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${funcoesController.nomeTraidpoint}",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      body: Stack(
        children: [
          // Conteúdo principal
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Impressoras disponíveis:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if(impressorasSelecionadas.isEmpty){
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Selecione pelo menos uma impressora"),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                            return;
                          }
                          String textoCupomAvulso = "Teste concluído com sucesso";
                          for(int i = 0; i < impressorasSelecionadas.length; i++){
                              String documentoProntoRetorno = await gerarDocumento(textoCupomAvulso, funcoesController.listaImpressoras[i]['colunas']);
                              await inserirServidorImpressao(
                                numeroDaLicencaSelecionada,
                                impressorasSelecionadas[i],
                                documentoProntoRetorno,
                                funcoesController.listaImpressoras[i]['colunas'],
                              );
                            }
                          /* for(int i = 0; i < funcoesController.listaImpressoras.length; i++){
                            String documentoProntoRetorno = await gerarDocumento(textoCupomAvulso, funcoesController.listaImpressoras[i]['colunas']);
                            await inserirServidorImpressao(
                              numeroDaLicencaSelecionada,
                              funcoesController.listaImpressoras[i]['numero'],
                              documentoProntoRetorno,
                              funcoesController.listaImpressoras[i]['colunas'],
                            );
                          } */
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Página de teste",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Grid impressoras
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const larguraMinimaCard = 100.0;
                      final crossAxisCount = (constraints.maxWidth / larguraMinimaCard).floor().clamp(1, 8);
              
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: funcoesController.listaImpressoras.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = funcoesController.listaImpressoras[index];
                          final nomeImpressora = item['nome'].toString();
                          final numeroImpressora = item['numero'].toString();

                          final selecionado = impressorasSelecionadas.contains(numeroImpressora);
                          // final selecionado = numeroImpressoraSelecionada.value == numeroImpressora;
                          return GestureDetector(
                            onTap: () {
                              if (selecionado) {
                                setState(() {
                                  impressorasSelecionadas.remove(numeroImpressora);
                                });
                              } else {
                                setState(() {
                                  impressorasSelecionadas.add(numeroImpressora);
                                });
                              }
                              /* setState(() {
                                numeroImpressoraSelecionada.value = numeroImpressora;
                                nomeImpressoraSelecionada.value = nomeImpressora;
                              }); */
                            },
                            child: Card(
                              color: selecionado
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerLow,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    nomeImpressora,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selecionado
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Digite o texto do cupom avulso:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              
                  // TextField 
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: TextField(
                        controller: textoCupomAvulsoController,
                        focusNode: textoCupomAvulsoFocusNode,
                        readOnly: false, // impede digitação pelo teclado nativo
                        showCursor: true, // FORÇA o cursor piscando
                        cursorColor: Theme.of(context).colorScheme.primary,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLines: 2, // nunca quebra
                        // textAlign: TextAlign.start, // evita estouro visual
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          /* fontSize: 22,
                          fontWeight: FontWeight.bold, */
                          overflow: TextOverflow.clip, // corta corretamente
                        ),
                        scrollPhysics: BouncingScrollPhysics(),
                        onTap: () {
                          FocusScope.of(context).requestFocus(textoCupomAvulsoFocusNode);
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "",
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.onSurface, // Cor da borda quando o campo NÃO tem foco
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary, // Cor da borda quando o campo TEM foco
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                          
                  // Botao para enviar o texto
                  isLoading ?
                  Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                  : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if(textoCupomAvulsoController.text.isEmpty || impressorasSelecionadas.isEmpty){
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Selecione o texto do cupom avulso e pelo menos uma impressora!',
                                ),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            isLoading = true;
                          });
                          try{
                            for(int i = 0; i < impressorasSelecionadas.length; i++){
                              String documentoProntoRetorno = await gerarDocumento(textoCupomAvulsoController.text, funcoesController.listaImpressoras[i]['colunas']);
                              await inserirServidorImpressao(
                                numeroDaLicencaSelecionada,
                                impressorasSelecionadas[i],
                                documentoProntoRetorno,
                                funcoesController.listaImpressoras[i]['colunas'],
                              );
                            }
                            limparPage();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cupom avulso impresso com sucesso!',
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }catch(e){
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao imprimir cupom avulso!',
                                ),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.55),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Imprimir',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}