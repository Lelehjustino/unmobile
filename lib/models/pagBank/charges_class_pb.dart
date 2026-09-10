import 'dart:ffi';

import 'package:un_recepcao/models/pagBank/phone_class_pb.dart';

class ChargesClassPb {
  String? id; // Identificador da cobrança PagBank.
  String? status;  // Status da cobrança.
  /* 
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
  Amount3ClassPb? amount; // Contém as informações do valor a ser cobrado.
  PaymentResponseClassPb? payment_response; // Contém informações de resposta do provedor de pagamento.
  PaymentMethodClassPb? payment_method; // Contém as informações do método de pagamento da cobrança.
  RecurringClassPb? recurring; 
  /*
  Contém as informações da recorrência. Os clientes que possuem recorrência própria devem utilizar esse parâmetro para indicar ao PagBank que a cobrança está relacionada a um pagamento recorrente.
  ⚠️ A utilização desse parâmetro não está vinculada à API de Pagamento Recorrente do PagBank. ⚠️ 
  */
  SubMerchantClassPb? sub_merchant; // Contém os dados do sub lojista, usado por sub-adquirentes para transações com Cartão de Crédito. ⚠️ Usado apenas por sub-adquirentes autorizados ⚠️
  Map? metadata; // Conjunto de pares de valores-chave que você pode anexar a um objeto. Isso pode ser útil para armazenar informações adicionais sobre o objeto em um formato estruturado.
  List<LinksClassPb>?links; 
  SplitsClassPb? splits;
}

class SplitsClassPb{
  Enum? method; // Define se os valores da divisão serão informados em valores brutos (FIXED) ou em porcentagens (PERCENTAGE) do valor total da transação.
  /*
  Valores de ENUM:

  FIXED
  PERCENTAGE
  */
  List<ReceiversClassPb>?receivers; 
}

class ReceiversClassPb {
  AmountClassPb? amount; // Contém informações dos valores dos recebedores participantes da divisão.
  AccountClassPb? account; // Contém informações das contas dos recebedores participantes da divisão de pagamento.
  ConfigurationsClassPb? configurations;
  String? reason; // Descrição opcional para cada recebedor participante da divisão do pagamento.
}

class ConfigurationsClassPb {
  CustodyClassPb? custody; // Contém informações das configurações de custódia.
  ChargebackClassPb? chargeback; // Contém informações das configurações de chargeback.
}

class CustodyClassPb{
  bool? apply; // Define se a transação terá custódia.
}

class ChargebackClassPb {
  ChargeTransferClassPb? charge_transfer;
}

class ChargeTransferClassPb {
  Double? percentage;
}

class AccountClassPb{
  String? id; // Identificador único da conta PagBank do recebedor.
}

class AmountClassPb{
  int? value; // Se a divisão utilizar a opção FIXED, esse valor é definido em centavos destinado ao recebedor. Se a divisão utilizar a opção PERCENTAGE, esse valor é o percentual do montante total destinado ao recebedor. Valor em centavos do montante destinado ao recebedor. Apenas números inteiros positivos.
}

class LinksClassPb{
  Enum? rel; // Indica o tipo do relacionamento ao recurso.
  String? href; // Endereço HTTP do recurso.
  String? media; // Tipo de mídia ao qual o link responde ou aceita.
  Enum? type; 
  /* Método HTTP em uso.
    Valores de ENUM:

    GET
    POST
    DELETE
    PUT 
  */
}

class SubMerchantClassPb {
  String? reference_id; // Identificador próprio referente ao lojista atribuído na plataforma do sub-adquirente.
  String? name; // Razão social do lojista na plataforma do sub-adquirente em caso de pessoa jurídica. Em casos de pessoa física, nome completo do lojista na plataforma do sub-adquirente.
  String? tex_id; // Número do documento (CPF ou CNPJ) do lojista na plataforma do sub-adquirente. ⚠️ Apenas números devem ser informados (com ou sem máscara). ⚠️
  String? mcc; // Código de atuação comercial do lojista (merchant category code) na plataforma do sub-adquirente. ⚠️Apenas números devem ser informados. Bloqueio padrão para MCC de alto risco. ⚠️
  AddressClassPb? address;
  PhoneClassPb? phone;
}

class RecurringClassPb {
  Enum? type; // Indica se a cobrança é proveniente de uma recorrência.
  /*
  Valores de ENUM:

  INITIAL para a primeira cobrança de uma recorrência.
  SUBSEQUENT para as cobranças subsequentes de uma recorrência.
  UNSCHEDULED para credenciais armazenadas sem data e valor fixo (somente iniciadas pelo comprador)
  STANDING ORDER para cobranças com data fixa e valores variáveis.
  */
  String? recurrence_id; // Identificador NRID retornado pela bandeira ELO, que deverá ser enviado nas transações subsequentes. ⚠️ Esse parâmetro está disponível apenas em transações com a bandeira Elo. ⚠️
  String? original_amount; // Valor original da primeira transação de recorrência. ⚠️ Esse parâmetro está disponível apenas em transações com a bandeira Elo. ⚠️
}

// 3 pq tem tres parametros
class Amount3ClassPb{
  int? value; // Valor a ser cobrado em centavos. Apenas números inteiros positivos.
  String? currency; // Código de moeda ISO de três letras, em maiúsculas. Por enquanto, apenas o Real brasileiro é suportado (“BRL”).
  SummaryClassPb? summary; // Contém um resumo de valores da cobrança.
}

class SummaryClassPb{
  int? total; // Valor total da cobrança.
  int? paid; // Valor que foi pago na cobrança.
  int? refunded; // Valor que foi devolvido da Cobrança.
}

class PaymentResponseClassPb{
  int? code; // Código PagBank que indica o motivo da resposta de autorização no pagamento, tanto para pagamento autorizado, quanto para negado.
  String? message; // Mensagem amigável descrevendo motivo da não aprovação ou autorização da cobrança. Compatível com o padrão ABECS - Normativo 21.
  String? reference; // NSU da autorização, caso o pagamento seja aprovado pelo Emissor.
  String? brand_reference_id; // NIdentificador NRID retornado pela bandeira ELO que deverá ser armazenado. ⚠️ Esse parâmetro está disponível apenas em transações com a bandeira Elo. ⚠️
}

class PaymentMethodClassPb{
  Enum? type; // Indica o método de pagamento usado na cobrança.
  /*
  Valores de ENUM:

  CREDIT_CARD ou DEBIT_CARD se o método de pagamento utilizado for Cartão de Crédito, Cartão de Débito ou Token de Bandeira. ⚠️ Obrigatório o envio do objeto payment_method.card. ⚠️
  BOLETO se o método de pagamento utilizado for Boleto. ⚠️ Obrigatório o envio do objeto payment_method.boleto. ⚠️
  PIX se o método de pagamento utilizado for Pix. ⚠️ O objeto payment_method.pix será criado no pagamento do qr code . ⚠️ 
  */
  int? installments; // Quantidade de parcelas. ⚠️ Obrigatório para o método de pagamento Cartão de Crédito. ⚠️
  bool? capture; 
  /*
    capture Boolean
    Parâmetro que indica se uma transação de Cartão de Crédito deve ser apenas pré-autorizada (reserva o valor da cobrança no cartão do cliente de 6 á 29 dias) ou se a transação deve ser capturada automaticamente (cobrança realizada em apenas um passo). ⚠️ Obrigatório para o método de pagamento Cartão de Crédito. Função indisponível para o método de pagamento Cartão de Débito e Token de Bandeira (débito). ⚠️

    Bandeiras de Cartão de Crédito: VISA, MASTERCARD, AMEX, ELO.
    Bandeiras de Token de Bandeira (Crédito): VISA, MASTERCARD, ELO.
    Informar true para cobrança em único passo. Informar false para pré-autorizar.
  */
  DateTime? capture_before; 
  /* 
    Data e horário limite para que seja feita a captura em uma transação com o status AUTHORIZED.
    Exemplo: 2023-02-18T15:15:11.881-03:00

    MASTERCARD,VISA e ELO permitirá à captura em até 29 dias para MCCs permitidos pelas bandeiras. Lista de MCCs disponíveis.
    Demais bandeiras permitirá à captura em até 6 dias.
  */
  String? soft_descriptor;
  CardClassPb? card; // Contém os dados de Cartão de Crédito, Cartão de Débito e Token de Bandeira. ⚠️ Obrigatório para o método de pagamento Cartão de Crédito, Cartão de Débito e Token de Bandeira. ⚠️
  TokenDataClassPb? token_data; // Contém os dados adicionais de Tokenização de Rede. ⚠️ Deve ser enviado quando um Cartão de Crédito ou Débito tokenizado pelas bandeiras Visa ou Mastercard é utilizado. ⚠️
  AuthenticationMethodClassPb? authentication_method; // Contém os dados adicionais de autenticação vinculados à uma transação. ⚠️ Obrigatório quando payment_method.type = DEBIT_CARD. ⚠️
  PaymentInstructionsClassPb? payment_instructions; // Contém as instruções de pagamento, incluindo regras de multa, juros e descontos.
  BoletoClassPb? boleto; // Contém os dados para geração do Boleto.
  PixClassPb? pix; // Contém os dados do pagamento do Pix.
}

class PixClassPb{
  String? end_to_end_id;
  HolderClassPb? holder;
}

class BoletoClassPb{
  String? due_date; // Data de vencimento do Boleto. Formato: “yyyy-MM-dd”
  String? Template; 
  /*
  Opções disponíveis:
  - COBRANCA : Usada para boletos com juros, multa, ou desconto.
  - PROPOSTA: Usada para boleto do tipo proposta.
  Exemplo: COBRANCA  
  */
  String? days_until_expiration; //Número de dias até a experição do Boleto.
  InstructionLinesClassPb? instruction_lines; // Contém as linhas de instrução do boleto.
  HolderBoletoClassPb? holder; // Contém as as informações do responsável pelo pagamento do Boleto.
}

class CardClassPb{
  int? id; // Identificador PagBank do Cartão de Crédito salvo (Cartão Tokenizado pelo PagBank). ⚠️ Função indisponível para o método de pagamento Cartão de Débito e Token de Bandeira. ⚠️
  String? number; // Número do Cartão de Crédito ou Cartão de Débito.
  String? network_token; // Número do Token de Bandeira.,
  int? exp_month; // Mês de expiração do Cartão de Crédito, Cartão de Débito ou Token de Bandeira.
  int? exp_year; // Ano de expiração do Cartão de Crédito, Cartão de Débito ou Token de Bandeira.
  String? security_code; // Código de Segurança do Cartão de Crédito, Cartão de Débito ou Token de Bandeira.
  bool? store; /* Indica se o cartão deverá ser armazenado no PagBank para futuras compras. ⚠️ Função indisponível para o método de pagamento Cartão de Débito e Token de Bandeira. ⚠️
  Informar false ou omitir este parâmetro fará com que o cartão não seja armazenado. Informar true fará com que o cartão seja armazenado. Na resposta da requisição irá receber o token do cartão em payment_method.card.id */ 
  String? brand; // Bandeira do cartão.
  String? product; // Retornado quando um Cartão de Crédito foi do tipo PRE_PAID.
  int? first_digits; // Seis primeiros números do Cartão ou Token de Bandeira (BIN).
  int? last_digits; // Quatro últimos números do Cartão ou Token de Bandeira.
  HolderClassPb? holder; // Contém as informações do portador do Cartão de Crédito, Cartão de Débito e Token de Bandeira.
}

class HolderClassPb{
  String? name; // Nome do portador do Cartão de Crédito, Cartão de Débito e Token de Bandeira.
  String? tax_id; // Número do documento (CPF ou CPNJ) do portador do Cartão de Crédito, Cartão de Débito e Token de Bandeira.
}

class TokenDataClassPb{
  String? requestor_id; // Identificador de quem gerou o Token de Bandeira (Token Requestor).
  Enum? wallet; 
  /*
  Tipo de carteira que armazenou o Token de Bandeira.
  Valores de ENUM:

  APPLE_PAY
  GOOGLE_PAY
  SAMSUNG_PAY
  MERCHANT_TOKENIZATION_PROGRAM
  */
  String? cryptogram; // Criptograma gerado pela bandeira.
  String? ecommerce_domain; // Identificador do domínio de origem da transação, comumente caracterizado em um formato de domínio reverso.
  int? assurance_level; // Conteúdo que indica o nível de confiança do token de rede.
}

class AuthenticationMethodClassPb{
  String? id; // Indica o ID da autenticação. Usado somente com o 3DS do PagBank. Prefixo 3DS_UUID.
  Enum? type; // Indica o método de autenticação utilizado na cobrança. ⚠️ Condicional para Token de Bandeira ELO. ⚠️
  /*
    Valores de ENUM:

    - THREEDS se o método de autenticação utilizado for 3DS.
    - INAPP se o método de autenticação utilizado for InApp.
  */
  String? cavv; // Identificador único gerado em cenário de sucesso de autenticação do cliente.
  String? eci; // Indicador E-Commerce retornado quando ocorre uma autenticação. Corresponde ao resultado da autenticação.
  String? xid; // Identificador de uma transação de um MPI - Recomendado para a bandeira VISA. ⚠️ Condicional para 3DS. ⚠️
  String? version; // Versão do protocolo 3DS utilizado na autenticação.
  String? dstrans_id; // ID da transação gerada pelo servidor de diretório durante uma autenticação - Recomendado para a bandeira Mastercard. ⚠️ Condicional para 3DS. ⚠️
  String? status; // Status de uma autenticação 3DS.
}

class PaymentInstructionsClassPb{
  FineClassPb? fine; // Define as regras de aplicação de multa por atraso.
  InterestClassPb? interest; // Define as regras de aplicação de juros por atraso.
  DiscountsClassPb? discounts; // Define as regras de desconto por pagamento antecipado.
}

class FineClassPb {
  String? date; // Data a partir da qual a multa é aplicada. Formato: YYYY-MM-DD.
  int? value; // Valor percentual da multa a ser cobrada. O valor deve ser enviado em centavos de porcentagem (ex: 2% = 200). Apenas números inteiros positivos.
}

class InterestClassPb {
  String? date; // Data a partir da qual os juros são aplicados. Formato: YYYY-MM-DD.
  int? value; // Valor percentual dos juros a ser cobrado. O valor deve ser enviado em centavos de porcentagem (ex: 2% = 200). Apenas números inteiros positivos.
}

class DiscountsClassPb {
  String? date; // Data limite para a aplicação do desconto (pagamento deve ocorrer até esta data). Formato: YYYY-MM-DD.
  int? value; // Valor percentual do desconto a ser aplicado. O valor deve ser enviado em centavos de porcentagem (ex: 2% = 200). Apenas números inteiros positivos.
}

class InstructionLinesClassPb{
  String? line_1; // Primeira linha de instruções sobre o pagamento do Boleto.
  String? line_2; // Segunda linha de instruções sobre o pagamento do Boleto.
}

class HolderBoletoClassPb {
  String? name; // Nome do responsável pelo pagamento do Boleto.
  String? tax_id; // Número do documento do responsável pelo pagamento do Boleto.
  String? email; // E-mail do responsável pelo pagamento do Boleto.
  AddressClassPb? address; // Contém informações do endereço do dono da conta ou sócio da empresa.
}

class AddressClassPb{
  String? street; // Rua do endereço.
  String? number; // Número do endereço.
  String? complement; // Complemento do endereço.
  String? locality; // Bairro do endereço.
  String? city; // Cidade do endereço.
  String? region; // Nome do Estado.
  String? region_code; // Código do Estado (Padrão ISO 3166-2).
  String? country; // País do endereço (Padrão ISO 3166-1 alpha-3).
  String? postal_code; // CEP do endereço.
}

