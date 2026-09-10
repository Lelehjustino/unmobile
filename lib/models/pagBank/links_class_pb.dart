import 'package:un_recepcao/models/pagBank/charges_class_pb.dart';

class LinksClassPb {
  Enum? rel; // Indica o tipo do relacionamento ao recurso.
  String? href; // Endereço HTTP do recurso.
  String? media; // Tipo de mídia ao qual o link responde ou aceita.
  Enum? type;
  /* 
  Método HTTP em uso.
  Valores de ENUM:

  GET
  POST
  DELETE
  PUT
  */
  WalletClassPb? wallet; // Contém os dados referentes a Wallet que está transacionando aquele pagamento. * Fluxo disponível apenas para transações de Wallets. *
}

class WalletClassPb {
  String? type; // Nome da wallet utilizada na transação.
  String? key; // Criptograma do cartão enviado pela wallet.
  PaymentMethodClassPb? payment_method;
}