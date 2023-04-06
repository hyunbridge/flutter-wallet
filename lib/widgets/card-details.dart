import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card.dart' as card_model;

Future<card_model.Card?> showCardDetails(
    BuildContext context, card_model.Card card, String title) async {
  TextEditingController cardNumberController =
      TextEditingController(text: addSpace(card.cardNumber));
  bool saveChanges = false;

  String displayName = "";
  String cardNumber = "";
  String expirationDate = "";
  String securityCode = "";

  final formKey = GlobalKey<FormState>();

  await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: card.displayName,
                    decoration: const InputDecoration(labelText: "카드 이름"),
                    onSaved: (text) => displayName = text ?? "",
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TextFormField(
                      controller: cardNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardNumberInputFormatter(),
                      ],
                      decoration: const InputDecoration(labelText: "카드 번호"),
                      onSaved: (text) =>
                          cardNumber = (text ?? "").replaceAll(' ', ''),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: card.securityCode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration:
                              const InputDecoration(labelText: "CVC/CVV"),
                          onSaved: (text) => securityCode = text ?? "",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: card.expirationDate,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            CardMonthInputFormatter(),
                          ],
                          decoration: const InputDecoration(labelText: "MM/YY"),
                          onSaved: (text) => expirationDate = text ?? "",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          insetPadding: const EdgeInsets.fromLTRB(0, 80, 0, 80),
          actions: [
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                formKey.currentState!.save();
                saveChanges = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
  if (saveChanges) {
    return card_model.Card(
      displayName,
      cardNumber,
      expirationDate,
      securityCode,
    );
  } else {
    return null;
  }
}

String addSpace(String input) {
  final buffer = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    buffer.write(input[i]);
    var index = i + 1; // Starts with 1
    if (index % 4 == 0 && index != input.length) {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    final string = addSpace(text);
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardMonthInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
