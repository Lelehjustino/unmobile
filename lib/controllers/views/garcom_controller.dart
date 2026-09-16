import 'dart:convert';

import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/data/data_class.dart';

class GarcomController extends GetxController {

  String cidadeEmpresa = "";
  String ufEmpresa = "";
  String telefoneEmpresa = "";

  RxBool cadastroCliente = false.obs;
  RxBool tipoCadastroClienteCpf = false.obs;
  RxBool tipoCadastroClienteTelefone = false.obs;
  RxBool forcarCadastroCliente = false.obs;
  RxBool modoCarrinhoComandas = false.obs;
  RxBool retirarBalcao = false.obs;
  RxBool retirarBalcaoRota = false.obs;
  RxBool vendaComanda = false.obs;
  RxBool vendaMesa = false.obs;
  RxBool vendaComandaNaMesa = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await carregarCidadeUf();
    await configuracoesCadastroCliente();
    await carregarModoCarrinhoComandas();
    await carregarRetiradaBalcao();
  }

  Future<void> configuracoesCadastroCliente() async {
    await carregarCadastroCliente();
    await carregarTipoCadastroCliente();
    await carregarForcarCadastroCliente();
  }

  Future<void> carregarRetiradaBalcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('retirar_balcao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se recepcao selecionado
        retirarBalcao.value = true;
      } else {
        // se recepcao nao selecionado
        retirarBalcao.value = false;
      }
    } else {
      // configuração padrao
      retirarBalcao.value = false;
    }
  }

  Future<void> carregarModoCarrinhoComandas() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('modo_carrinho_comandas');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se recepcao selecionado
        modoCarrinhoComandas.value = true;
      } else {
        // se recepcao nao selecionado
        modoCarrinhoComandas.value = false;
      }
    } else {
      // configuração padrao
      modoCarrinhoComandas.value = false;
    }
  }

  Future<void> carregarForcarCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('forcar_cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se recepcao selecionado
        forcarCadastroCliente.value = true;
      } else {
        // se recepcao nao selecionado
        forcarCadastroCliente.value = false;
      }
    } else {
      // configuração padrao
      forcarCadastroCliente.value = false;
    }
  }

  // Carregar cadastro cliente
  Future<void> carregarCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se recepcao selecionado
        cadastroCliente.value = true;
      } else {
        // se recepcao nao selecionado
        cadastroCliente.value = false;
      }
    } else {
      // configuração padrao
      cadastroCliente.value = false;
    }
  }

  // Carregar tipo de cadastro cliente
  Future<void> carregarTipoCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('tipo_cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0') && !recepcaosSalvos.contains('1')) {
        // se recepcao selecionado
        tipoCadastroClienteCpf.value = true;
        tipoCadastroClienteTelefone.value = false;
      } else if (!recepcaosSalvos.contains('0') && recepcaosSalvos.contains('1')) {
        // se recepcao nao selecionado
        tipoCadastroClienteCpf.value = false;
        tipoCadastroClienteTelefone.value = true;
      } else {
        // se recepcao nao selecionado
        tipoCadastroClienteCpf.value = false;
        tipoCadastroClienteTelefone.value = true;
      }
    } else {
      // configuração padrao
      tipoCadastroClienteCpf.value = false;
      tipoCadastroClienteTelefone.value = true;
    }
  }

  // Função para carregar cidade e uf
  Future<void> carregarCidadeUf() async {
    String telefoneEmpresaLocal = '';
    try {
      String dadosJson = await Connection().select(
        "SELECT telefone, cidade, uf FROM empresa WHERE numero='1' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        cidadeEmpresa = lista[0]['cidade'].toString();
        ufEmpresa = lista[0]['uf'].toString();
        telefoneEmpresaLocal = lista[0]['telefone'].toString();
      }

      String codigoArea = telefoneEmpresaLocal.substring(1, 3);
      telefoneEmpresa = codigoArea;
    } catch (e) {
      cidadeEmpresa = '';
      ufEmpresa = '';
    }
  }

  String obterDataHoraMysql() {
    final now = DateTime.now();
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return "${now.year}-"
        "${doisDigitos(now.month)}-"
        "${doisDigitos(now.day)} "
        "${doisDigitos(now.hour)}:"
        "${doisDigitos(now.minute)}:"
        "${doisDigitos(now.second)}";
  }

  // Função quando cliente não existe
  /* Future<void> abrirCliente(
    nomeCliente,
    cpfCliente,
    dataNascimentoCliente,
    telefoneCliente
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";
    String dataCadastroFormatado = obterDataHoraMysql();

    String nome = nomeCliente.toUpperCase();
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;

    try {
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      if (telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // String sql = '''INSERT INTO clientes (nome, cidade, uf, cpf, sexo, datanascimento, telefone, observacao) VALUES ('LE', '', '', $cpf, $sexo, $dataNascimentoFormatada, $telefoneClienteFormatado, ''); ''';
    String sql =
        '''
      INSERT INTO clientes 
      (nome, cidade, uf, cpf, datanascimento, telefone, observacao, dataCadastro)
      VALUES ('$nome', '$cidade', '$uf', '$cpf', '$dataNascimentoFormatada', '$telefoneClienteFormatado', '$observacao', '$dataCadastroFormatado');
    ''';
    try {
      String resultado = await Connection().ipd(sql);
      print(sql);
      if (resultado == 'sucesso') {
        print("Pedido aberto com sucesso para comanda ");
      } else {
        print(" Erro ao abrir pedido: $resultado");
      }
    } catch (e) {
      print(" Erro inesperado: $e");
    }
  } */

 Future<int> abrirCliente(
    nomeCliente,
    cpfCliente,
    dataNascimentoCliente,
    telefoneCliente
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";
    String dataCadastroFormatado = obterDataHoraMysql();

    String nome = nomeCliente.toUpperCase();
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;

    try {
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      if (telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // String sql = '''INSERT INTO clientes (nome, cidade, uf, cpf, sexo, datanascimento, telefone, observacao) VALUES ('LE', '', '', $cpf, $sexo, $dataNascimentoFormatada, $telefoneClienteFormatado, ''); ''';
    String sql =
        '''
      INSERT INTO clientes 
      (nome, cidade, uf, cpf, datanascimento, telefone, observacao, dataCadastro)
      VALUES ('$nome', '$cidade', '$uf', '$cpf', '$dataNascimentoFormatada', '$telefoneClienteFormatado', '$observacao', '$dataCadastroFormatado');
    ''';
    try {
    String idCliente = await Connection().insertId(sql);

      if (idCliente.isNotEmpty) {
        return int.parse(idCliente);
      }

      return 0;
    } catch (e) {
      print("Erro: $e");
      return 0;
    }
  }

  Future<String> atualizarClientePorNumero(
    String nomeCliente,
    String cpfCliente,
    String dataNascimentoCliente,
    String telefoneCliente,
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";

    String nome = nomeCliente;
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;

    try {
      // Tenta converter a data para o formato yyyy-MM-dd
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      // Formata telefone padrão
      if (telefoneCliente.trim().isEmpty ||
          telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE clientes
      SET 
        nome = '$nome',
        cidade = '$cidade',
        uf = '$uf',
        cpf = '$cpf',
        datanascimento = '$dataNascimentoFormatada',
        telefone = '$telefone',
        observacao = '$observacao'
      WHERE telefone = '$telefone';
    '''; 

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }

    return resultado;
  }
  
  Future<String?> buscarNumeroClientePorTelefone (String telefoneCliente) async {
    try {
      String telefoneClienteFormatado = "";

      String dadosJson = await Connection().select(
        "SELECT numero FROM clientes WHERE telefone='$telefoneCliente'",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        String numero = lista[0]['numero'].toString();
        return numero;
      } else {
        return "0";
      }
    } catch (e) {
    }
  }

  Future<String?> buscarNumeroClientePorCpf(cpf) async {
    String telefoneEmpresaLocal = '';
    try {
      String dadosJson = await Connection().select(
        "SELECT numero FROM clientes WHERE cpf='$cpf'",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        String numero = lista[0]['numero'].toString();
        return numero;
      } else {
        return "0";
      }
    } catch (e) {
    }
  }

  // Função quando cliente já existe por cpf
  Future<String> atualizarClientePorCpf(
    String nomeCliente,
    String cpfCliente,
    String dataNascimentoCliente,
    String telefoneCliente,
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";

    String nome = nomeCliente.toUpperCase();
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;

    try {
      // Tenta converter a data para o formato yyyy-MM-dd
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      // Formata telefone padrão
      if (telefoneCliente.trim().isEmpty ||
          telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE clientes
      SET 
        nome = '$nome',
        cidade = '$cidade',
        uf = '$uf',
        cpf = '$cpf',
        datanascimento = '$dataNascimentoFormatada',
        telefone = '$telefone',
        observacao = '$observacao'
      WHERE cpf = '$cpf';
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }

    return resultado;
  }
}