// Contém informações do cliente que fará pagamentos usando o serviço PagBank.
import 'dart:ffi';

import 'package:un_recepcao/models/pagBank/phone_class_pb.dart';

class CustomerClassPb {
  String? name;
  String? email;
  String? tax_id; // Documento de identificação pessoal (CPF/CNPJ) do cliente. Obrigatório.
  List<PhoneClassPb>? phone;
}