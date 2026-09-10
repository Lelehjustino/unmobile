class ShippingClassPb {
  AddressClassPb? address;
}

class AddressClassPb{
  String? street; // Rua do endereço
  String? number; // Numero endereço
  String? complement; // Complemento endereço
  String? locality; // Bairro endereço
  String? city; // Cidade do endereço 
  String? region; // Nome do estado
  String? region_code; // Codigo do estado 
  String? country; // pais
  String? postal_code;
}