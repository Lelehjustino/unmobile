class QrCodesClassPb {
  DateTime? expiration_date; // Data de expiração do QR Code. 
  /* Por padrão, o QR Code gerado tem validade até as 23h59m do dia seguinte caso o parâmetro qr_codes.expiration_date não seja definido na requisição.*/
  Amount1ClassPb? amount; // Contém informações do valor a ser utilizado no QR Code
  SplitsClassPb? splits; // Contém informações da divisão de pagamento.
}

class Amount1ClassPb{
  int? value; // Valor int 
}

class SplitsClassPb {
  Enum? method;
  /*Define se os valores da divisão serão informados em valores brutos (FIXED) ou em porcentagens (PERCENTAGE) do valor total da transação.
  Valores de ENUM:

  FIXED
  PERCENTAGE */
  List<ReceiversClassPb>? receivers;
}

class ReceiversClassPb {
  Amount1ClassPb? amount; // Contém informações dos valores dos recebedores participantes da divisão
  AccountClassPb? account; // Contém informações das contas dos recebedores participantes da divisão de pagamento.
  ConfigurationsClassPb? configurations; // Contém informações das configurações dos recebedores participantes da divisão.
  String? reason; // Descrição opcional para cada recebedor participante da divisão do pagamento.
}

class AccountClassPb {
  int? id;
}

class ConfigurationsClassPb{
  CustodyClassPb? custody; // Contém informações das configurações de custódia.
}

class CustodyClassPb {
  bool? apply; // Define se a transação terá custódia.
}