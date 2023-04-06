import 'dart:async';

import 'package:credit_card_scanner/credit_card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:wallet/utils/db.dart';

import '../models/card.dart' as card_model;
import '../widgets/card-details.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StreamController<bool> _verificationNotifier =
  StreamController<bool>.broadcast();

  Future<List<card_model.Card>> getCards() async {
    try {
      return HiveHelper().getAll();
    } catch (_) {
      final navigator = Navigator.of(context);
      await SchedulerBinding.instance.endOfFrame;

      await navigator.push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PasscodeScreen(
          title: const Text(
            '패스코드 입력',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28),
          ),
          cancelButton: const SizedBox.shrink(),
          deleteButton: const Text(
            '삭제',
            style: TextStyle(fontSize: 16),
            semanticsLabel: '삭제',
          ),
          circleUIConfig: const CircleUIConfig(
              borderColor: Colors.black, fillColor: Colors.black),
          keyboardUIConfig: const KeyboardUIConfig(
            primaryColor: Colors.black,
            digitTextStyle: TextStyle(fontSize: 30, color: Colors.black),
          ),
          shouldTriggerVerification: _verificationNotifier.stream,
          backgroundColor: Colors.white,
          passwordDigits: 6,
          passwordEnteredCallback: (String password) async {
            try {
              await HiveHelper().init(password);
              _verificationNotifier.add(true);
            } catch (e) {
              _verificationNotifier.add(false);
            }
          },
          isValidCallback: () => navigator.maybePop(),
          cancelCallback: () {},
        ),
      ));
      return HiveHelper().getAll();
    }
  }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: getCards(),
          builder: (context, snapshot) {
            List<Widget> slivers = [];
            if (snapshot.hasError) {
              slivers.add(
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: Text('Error: ${snapshot.error}',
                          textAlign: TextAlign.center)),
                ),
              );
            }

            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                slivers.add(
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        "카드가 없습니다.",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                );
              } else {
                slivers.add(
                  SliverList(
                    delegate: SliverChildListDelegate(
                      List.generate(snapshot.data!.length, (i) {
                        final card_model.Card card = snapshot.data![i];
                        return ListTile(
                          title: Text(card.displayName),
                          subtitle: card.cardNumber.length >= 4
                              ? Text(
                              "${card.cardNumber.substring(card.cardNumber.length - 4)}(으)로 끝남")
                              : null,
                          onTap: () async {
                            final modified = await showCardDetails(
                                context, card, "카드 열람/수정");
                            if (modified != null) {
                              await HiveHelper().update(card.key, modified);
                              setState(() {});
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('삭제하시겠습니까?'),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: const <Widget>[
                                        Text('삭제된 카드는 복구할 수 없습니다.'),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('취소'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('삭제'),
                                      onPressed: () async {
                                        final navigator = Navigator.of(context);

                                        await card.delete();
                                        setState(() {});

                                        navigator.pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }
            } else {
              slivers.add(
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  floating: false,
                  pinned: true,
                  snap: false,
                  stretch: true,
                  title: Text("내 카드"),
                ),
                ...slivers
              ],
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          card_model.Card? prefilledDetails;

          final navigator = Navigator.of(context);

          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('카드 추가'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    ListTile(
                      title: const Text("카드 스캔"),
                      onTap: () async {
                        final cardDetails = await CardScanner.scanCard(
                          scanOptions:
                          const CardScanOptions(enableLuhnCheck: false),
                        );
                        if (cardDetails != null) {
                          prefilledDetails = card_model.Card(
                            "",
                            cardDetails.cardNumber,
                            cardDetails.expiryDate,
                            "",
                          );
                        }
                        navigator.pop();
                      },
                    ),
                    ListTile(
                      title: const Text("직접 입력"),
                      onTap: () {
                        prefilledDetails = card_model.Card("", "", "", "");
                        navigator.pop();
                      },
                    ),
                  ]),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('닫기'),
                    onPressed: () {
                      navigator.pop();
                    },
                  ),
                ],
              );
            },
          );
          if (prefilledDetails != null && mounted) {
            final card =
            await showCardDetails(context, prefilledDetails!, "카드 추가");
            if (card != null) {
              await HiveHelper().add(card);
              setState(() {});
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
