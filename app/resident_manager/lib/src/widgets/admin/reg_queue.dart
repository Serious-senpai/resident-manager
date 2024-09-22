import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../../utils.dart";
import "../../core/config.dart";
import "../../core/translations.dart";
import "../../core/models/reg_request.dart";

class RegisterQueuePage extends StateAwareWidget {
  const RegisterQueuePage({super.key, required super.state});

  @override
  RegisterQueuePageState createState() => RegisterQueuePageState();
}

class RegisterQueuePageState extends AbstractCommonState<RegisterQueuePage> with CommonStateMixin<RegisterQueuePage> {
  List<RegisterRequest> _requests = [];
  int _offset = 0;
  Future<bool>? _queryFuture;

  int get offset => _offset;
  set offset(int value) {
    _offset = value;
    _queryFuture = null;
    refresh();
  }

  Future<bool> queryRegistrationRequests() async {
    try {
      _requests = await RegisterRequest.query(state: state, offset: DB_PAGINATION_QUERY * offset);
      refresh();
      return true;
    } catch (_) {
      await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
      return false;
    }
  }

  @override
  Scaffold buildScaffold(BuildContext context) {
    _queryFuture ??= queryRegistrationRequests();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.how_to_reg_outlined),
        ),
        title: Text(AppLocale.RegisterQueue.getString(context)),
      ),
      body: FutureBuilder(
        future: _queryFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox.square(
                      dimension: 50,
                      child: CircularProgressIndicator(),
                    ),
                    const SizedBox.square(dimension: 20),
                    Text(AppLocale.Loading.getString(context)),
                  ],
                ),
              );

            case ConnectionState.done:
              final success = snapshot.data ?? false;
              if (success) {
                const headerStyle = TextStyle(fontWeight: FontWeight.bold);
                TableCell header(String text) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(text, style: headerStyle),
                      ),
                    );
                TableCell row(String text) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(text),
                      ),
                    );

                final rows = [
                  TableRow(
                    decoration: const BoxDecoration(border: BorderDirectional(bottom: BorderSide(width: 1))),
                    children: [
                      header(AppLocale.Name.getString(context)),
                      header(AppLocale.Room.getString(context)),
                      header(AppLocale.DateOfBirth.getString(context)),
                      header(AppLocale.Phone.getString(context)),
                      header(AppLocale.Email.getString(context)),
                      header(AppLocale.CreationTime.getString(context)),
                    ],
                  ),
                ];

                for (final request in _requests) {
                  rows.add(
                    TableRow(
                      children: [
                        row(request.name),
                        row(request.room.toString()),
                        row(request.birthday?.toString() ?? "---"),
                        row(request.phone ?? "---"),
                        row(request.email ?? "---"),
                        row(request.createdAt.toString()),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Table(children: rows),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_outlined),
                            onPressed: () {
                              if (offset > 0) {
                                offset--;
                              }
                              refresh();
                            },
                          ),
                          Text((offset + 1).toString()),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_outlined),
                            onPressed: () {
                              if (_requests.isNotEmpty) {
                                offset++;
                              }
                              refresh();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 50,
                    child: Icon(Icons.highlight_off_outlined),
                  ),
                  const SizedBox.square(dimension: 20),
                  Text(AppLocale.ConnectionError.getString(context)),
                ],
              );
          }
        },
      ),
      drawer: createDrawer(context),
    );
  }
}
