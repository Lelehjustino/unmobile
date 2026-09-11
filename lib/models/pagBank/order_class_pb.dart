import 'package:flutter/material.dart';
import 'package:un_recepcao/models/pagBank/charges_class_pb.dart';
import 'package:un_recepcao/models/pagBank/customer_class_pb.dart';
import 'package:un_recepcao/models/pagBank/items_class_pb.dart';
import 'package:un_recepcao/models/pagBank/qr_codes_class_pb.dart';
import 'package:un_recepcao/models/pagBank/shipping_class_pb.dart';

class OrderClassPb {
  String? id; // Identificador do pedido PagBank.
  String? reference_id; // Identificador único atribuído para o pedido.
  CustomerClassPb? customer;
  ItemsClassPb? items; // Contém as informações dos itens inseridos no pedido.
  List<ShippingClassPb>? shipping; // Contém as informações de entrega do pedido.
  List<QrCodesClassPb>?qr_codes; // Objeto contendo os QR Codes vinculados à um pedido.
  List<String>? notification_urls; // nao sei 
  List<ChargesClassPb>?charges; // Representa todos os dados disponíveis em uma cobrança, ou seja, na iniciação de um pagamento.
  List<LinksClassPb>?links; 

  
}