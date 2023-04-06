import 'package:hive/hive.dart';
part 'card.g.dart';

@HiveType(typeId: 0)
class Card extends HiveObject {
  @HiveField(0)
  String displayName;

  @HiveField(1)
  String cardNumber;

  @HiveField(2)
  String expirationDate;

  @HiveField(3)
  String securityCode;

  Card(this.displayName, this.cardNumber, this.expirationDate,
      this.securityCode);
}
