import 'package:un_recepcao/models/pagBank/charges_class_pb.dart';
import 'package:un_recepcao/models/pagBank/qr_codes_class_pb.dart';

class ChargeClassPb {
  String? id; // Identificador da cobrança PagBank.
  String? status; 
  /* 
  Status da cobrança.

  AUTHORIZED indica que a cobrança está pré-autorizada.
  PAID indica que a cobrança está paga (capturada).
  IN_ANALYSIS indica que o comprador optou por pagar com um Cartão de Crédito e o PagBank está analisando o risco da transação.
  DECLINED Indica que a cobrança foi negada pelo PagBank ou Emissor.
  CANCELED indica que a cobrança foi cancelada.
  WAITING Indica que a cobrança está aguardando pagamento.
  */
  DateTime? created_at; // Data e horário em que foi criada a cobrança.
  DateTime? paid_at; // Data e horário em que a cobrança foi paga (capturada).
  String? reference_id; // Identificador único atribuído para a cobrança.
  String? description; // Descrição da cobrança.
  AmountClassPb? amount; // Contém as informações do valor a ser cobrado.
  PaymentResponseChargeClassPb? payment_response; // Contém informações de resposta do provedor de pagamento.
  PaymentMethodClassPb? payment_method; // Contém as informações do método de pagamento da cobrança.
  List<QrCodesClassPb>?qr_codes; 
  /*
  Objeto contendo os QR Codes vinculados à um pedido. 
  Ao informar o amount, o QR code será gerado automaticamente e pode ser pago com aplicativos de outras instituições (Pix). 
  ⚠️ Para que o QR Code aceite o pagamento Pix, o vendedor precisa ter pelo menos uma chave de endereçamento ativa vinculada a sua conta PagBank. 
  ⚠️ Caso o vendedor tenha mais de uma chave de endereçamento cadastrada no PagBank, priorizaremos a utilização da chave de endereçamento aleatória. 
  */
}

class PaymentResponseChargeClassPb{
  int? code; // Código PagBank que indica o motivo da resposta de autorização no pagamento, tanto para pagamento autorizado, quanto para negado.
  String? message; // Mensagem amigável descrevendo motivo da não aprovação ou autorização da cobrança. Compatível com o padrão ABECS - Normativo 21.
  String? reference; // NSU da autorização, caso o pagamento seja aprovado pelo Emissor.
  RawDataClassPb? raw_data; // Contém informações puras vindas dos emissores/bandeiras
}

class RawDataClassPb{
  int? authorization_code; // Código de autorização gerado no momento da tentativa de autorização da transação.
  String? nsu; // Código identificador único gerado para transações de crédito e débito, nesses dois cenários será o mesmo valor enviado no campo payment_responde.reference
  String? reason_code; // Código de retorno enviado pela bandeira/emissor sem sofrer normatizações por parte do Pagbank, possibilitando assim análises junto da bandeira pelas negativas da transação.
  String? merchant_advice_code; // Código complementar ao reason_code (exclusivo atualmente para a Mastercard)
}

class AmountClassPb{
  int? value; // Valor a ser cobrado em centavos. Apenas números inteiros positivos.
  String? currency; // Código de moeda ISO de três letras, em maiúsculas. Por enquanto, apenas o Real brasileiro é suportado (“BRL”).
  SummaryClassPb? summary; // Contém um resumo de valores da cobrança.
}

class SummaryClassPb {
  int? total; // Valor total da cobrança.
  int? paid; // Valor que foi pago na cobrança.
  int? refunded; // Valor que foi devolvido da Cobrança.
}