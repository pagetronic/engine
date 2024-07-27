import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/ux.dart';
import 'package:engine/utils/widgets/form/suggest_picker.dart';
import 'package:flutter/material.dart';

class ShareBox extends StatefulWidget {
  final ValueNotifier<List<String>?> share = ValueNotifier([]);
  final void Function(List<String>? value) onChanged;
  final String infos;

//TODO test  SubscriptionUtils.testSubscription(context, Subscription.premium, widget.infos, onSubscribed: toggle)
  ShareBox({super.key, List<String>? share, required this.infos, required this.onChanged}) {
    this.share.value = share;
  }

  @override
  State<StatefulWidget> createState() {
    return ShareBoxState();
  }

  void testSubscription() {}
}

class ShareBoxState extends State<ShareBox> {
  final Map<String, Json> users = {};

  @override
  Widget build(BuildContext context) {
    AppLocalizations local = Language.of(context);
    builder(BuildContext context, AsyncSnapshot<Json?> snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Ux.loading(context);
      }
      if (snapshot.data != null && snapshot.data!['result'] != null) {
        for (Json result in snapshot.data!.result) {
          users[result.id!] = result;
        }
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
              onPressed: () {
                toggle() {
                  setState(() {
                    if (widget.share.value != null) {
                      widget.share.value!.clear();
                      widget.share.value = null;
                    } else {
                      widget.share.value = [];
                    }
                  });
                  widget.onChanged(widget.share.value);
                }

                if (widget.share.value == null) {
                  toggle();
                  widget.testSubscription();
                } else {
                  toggle();
                }
              },
              icon: Icon(widget.share.value != null ? Icons.lock : Icons.lock_open,
                  color: widget.share.value != null ? Colors.red : Colors.green),
              label: Text(widget.share.value != null ? local.private : local.public)),
          const SizedBox(width: 5),
          if (widget.share.value != null)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (String id in widget.share.value!)
                    InkWell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (users[id] != null && users[id]!['avatar'] != null)
                              ImageWidget.json(users[id]!['avatar'], format: ImageFormat.png36x36),
                            if (users[id] != null && users[id]!['avatar'] == null)
                              const Icon(Icons.person, size: 36, color: Colors.grey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    users[id] != null && users[id]!['name'] != null ? users[id]!['name'] : id,
                                    softWrap: true,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (users[id] != null)
                                    Text(
                                      (users[id]!['idn'] ?? users[id]!.id) +
                                          (users[id]!['email'] != null ? " > ${users[id]!['email']}" : ""),
                                      softWrap: true,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                ],
                              ),
                            ),
                            SuggestPick(
                                active: true,
                                onSelect: () {
                                  setState(() {
                                    List<String>? share = widget.share.value;
                                    if (share != null) {
                                      share.remove(id);
                                      widget.share.value = share;
                                    }
                                  });
                                  widget.onChanged(widget.share.value);
                                })
                          ],
                        ),
                      ),
                    ),
                  UsersPicker(
                    users: widget.share.value == null
                        ? []
                        : [
                            for (String id in widget.share.value!)
                              if (users[id] != null) users[id]!
                          ],
                    onSelect: (List<Json> users) {
                      List<String> share = [];
                      for (Json user in users) {
                        this.users[user.id!] = user;
                        share.add(user.id!);
                      }
                      setState(() {
                        widget.share.value = share;
                      });
                      widget.onChanged(share);
                    },
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (widget.share.value == null) {
      return builder(context, AsyncSnapshot.withData(ConnectionState.done, Json()..["result"] = users.values));
    }
    return FutureBuilder(
        future: Api.post("/users", Json({"action": "value", "ids": widget.share.value})), builder: builder);
  }
}
