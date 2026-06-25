import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';

// IMPORTAR: final NavegacaoInteligente navegacaoInteligente = Get.find<NavegacaoInteligente>();
// CHAMAR: navegacaoInteligente.carregarNavegacao();
// CHAMAR: navegacaoInteligente.navegacaoInteligente();
// USAR DIRETO: Get.find<NavegacaoInteligente>().navegacaoInteligente();

class NavegacaoInteligente extends GetxController {

  // Varipaveis para controle de navegação
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = false;
  bool aparecerGarcom = false;
  bool aparecerNote = false;
  bool aparecerCheckInOut = false;

  // Função para carregar navegação inteligente
  Future<void> carregarNavegacao() async {
    await carregarModos();
    await carregarchecks();
    await carregargarcom();
    await carregarNote();
    await carregarRecepcao();
  }

  // Carregar Modos
  Future<void> carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
        aparecerCheckInOut = false;
        naoAparecerMapa = false;
      } else if (modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        aparecerCheckInOut = true;
        naoAparecerMapa = false;
      } else if (!modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        aparecerCheckInOut = true;
        naoAparecerMapa = false;
      } else if(!modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")){
          naoAparecerMapa = true;
          aparecerCheckInOut = false;
      }
      else {
        aparecerCheckInOut = true;
        naoAparecerMapa = false;
      }

    } else {  // Se não tiver nada salvo, define padrão
        aparecerCheckInOut = true;
        naoAparecerMapa = false;
    }
  }

  // Carregar check 
  Future<void> carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
        aparecerCheckIn = true;
        aparecerCheckOut = false;
      } else if (checksSalvos.contains("Check-out") && !checksSalvos.contains("Ckeck-in")) {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
      } else if (!checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
      } else if(checksSalvos.contains("Ckeck-in") && checksSalvos.contains("Check-out")){
          aparecerCheckIn = true;
          aparecerCheckOut = true;
      }
      else {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
      }

    } else {  // Se não tiver nada salvo, define padrão
        aparecerCheckIn = true;
        aparecerCheckOut = true;
    }
  }

  // Carregar garçom
  Future<void> carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));

      if (garcomSalvos.contains("Sim") && !garcomSalvos.contains("Não")) {
        aparecerGarcom = true;
      } else if (!garcomSalvos.contains("Sim") && garcomSalvos.contains("Não")) {
        aparecerGarcom = false;
      } else if (!garcomSalvos.contains("Sim") && !garcomSalvos.contains("Não")) {
          aparecerGarcom = true;
      } else if(garcomSalvos.contains("Sim") && garcomSalvos.contains("Não")){
          aparecerGarcom = true;
      }
      else {
          aparecerGarcom = true;
      }

    } else {  // Se não tiver nada salvo, define padrão
        aparecerGarcom = true;
    }
  }

  // Carregar note
  Future<void> carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('Notes')) { // se note selecionado
        aparecerNote = true;
      } else { // se note nao selecionado
        aparecerNote = false;
      }

    } else { // configuração padrao 
      aparecerNote = false;
    }
  }

  // Carregar recepcao
  Future<void> carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('Recepção')) { // se recepcao selecionado
        aparecerRecepcao = true;
      } else { // se recepcao nao selecionado
        aparecerRecepcao = false;
      }

    } else { // configuração padrao 
      aparecerRecepcao = false;
    }
  }

  Future<void> navegacaoInteligente() async {
     if(aparecerCheckIn){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => CheckinPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      );
    } else if(aparecerCheckOut){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => CheckoutPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      );
    } else if (!naoAparecerMapa){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => MapaPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      );
    } else if(aparecerGarcom){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => GarcomPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      );
    } else if (aparecerRecepcao){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => RecepcaoPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      );
    } else if (aparecerNote){
      Navigator.push(
        Get.context!,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => NotesPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      ); 
    } else {
      ScaffoldMessenger.of(Get.context!,).showSnackBar(
        SnackBar(
          content: Text('Não foi possível entrar na aplicação, tente novamente'),
          backgroundColor: Theme.of(Get.context!,).colorScheme.error,
        ),
      );
      /* Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration.zero, // sem duração
          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
          pageBuilder: (context, animation, secondaryAnimation,) => ConfiguracoesPage(),
          transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            return child; // retorna direto, sem animação
          },
        ),
      ); */
    }
  }
}