class PhoneClassPb {
  int? country; // Código de operadora do País (DDI).
  int? area; // Código de operadora local (DDD).
  int? number; // Número do telefone.
  String? type; 
  /*
    Indica o tipo de telefone.
    Valores de ENUM:

    MOBILE se for um telefone celular.
    BUSINESS se for um telefone comercial.
    HOME se for um telefone residencial.
   */
}