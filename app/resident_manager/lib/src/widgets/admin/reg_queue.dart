import "dart:async";
import "dart:io";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../utils.dart";
import "../../utils.dart";
import "../../core/config.dart";
import "../../core/state.dart";
import "../../core/translations.dart";
import "../../core/models/reg_request.dart";
import "../../core/models/snowflake.dart";

class RegisterQueuePage extends StateAwareWidget {
  const RegisterQueuePage({super.key, required super.state});

  @override
  RegisterQueuePageState createState() => RegisterQueuePageState();
}

class RegisterQueuePageState extends AbstractCommonState<RegisterQueuePage> with CommonStateMixin<RegisterQueuePage> {
  List<RegisterRequest> _requests = [];
  int _offset = 0;
  int _offsetLimit = 0;

  Future<bool>? _queryFuture;
  Future<int?>? _countFuture;
  Widget _notification = const SizedBox.square(dimension: 0);

  final _selectedRequests = <RegisterRequest>{};
  final _actionLock = Lock();

  final _userSearch = TextEditingController();
  final _roomSearch = TextEditingController();

  int get offset => _offset;
  set offset(int value) {
    _offset = value;
    _queryFuture = null;
    _countFuture = null;
    refresh();
  }

  Future<void> _approveOrReject(Future<bool> Function({required Iterable<Snowflake> objects, required ApplicationState state}) coro) async {
    await _actionLock.run(
      () async {
        _notification = TranslatedText(
          (ctx) => AppLocale.Loading.getString(ctx),
          state: state,
          style: const TextStyle(color: Colors.blue),
        );
        refresh();

        var success = false;
        try {
          success = await coro(state: state, objects: _selectedRequests);
        } catch (e) {
          if (e is SocketException || e is TimeoutException) {
            await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
          } else {
            rethrow;
          }
        }

        if (success) {
          _notification = const SizedBox.square(dimension: 0);
          _selectedRequests.clear();
          offset = 0;
        } else {
          _notification = TranslatedText(
            (ctx) => AppLocale.UnknownError.getString(ctx),
            state: state,
            style: const TextStyle(color: Colors.red),
          );
          refresh();
        }
      },
    );
  }

  Future<bool> queryRegistrationRequests() async {
    try {
      _requests = await RegisterRequest.query(
        state: state,
        offset: DB_PAGINATION_QUERY * offset,
        name: _userSearch.text,
        room: int.tryParse(_roomSearch.text),
      );
      refresh();
      return true;
    } catch (_) {
      await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
      return false;
    }
  }

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _queryFuture ??= queryRegistrationRequests();
    _countFuture ??= RegisterRequest.count(state: state).then(
      (value) {
        if (value != null) {
          _offsetLimit = (value + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1;
        } else {
          _offsetLimit = offset;
        }

        return _offsetLimit;
      },
    );

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.menu_outlined),
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
                      TableCell(
                        child: Checkbox.adaptive(
                          value: _selectedRequests.containsAll(_requests),
                          onChanged: (state) {
                            if (state != null) {
                              if (state) {
                                _selectedRequests.addAll(_requests);
                              } else {
                                _selectedRequests.removeAll(_requests);
                              }
                            }

                            refresh();
                          },
                        ),
                      ),
                      header(AppLocale.Fullname.getString(context)),
                      header(AppLocale.Room.getString(context)),
                      header(AppLocale.DateOfBirth.getString(context)),
                      header(AppLocale.Phone.getString(context)),
                      header(AppLocale.Email.getString(context)),
                      header(AppLocale.CreationTime.getString(context)),
                      header(AppLocale.Username.getString(context)),
                    ],
                  ),
                ];

                for (final request in _requests) {
                  rows.add(
                    TableRow(
                      children: [
                        Checkbox.adaptive(
                          value: _selectedRequests.contains(request),
                          onChanged: (state) {
                            if (state != null) {
                              if (state) {
                                _selectedRequests.add(request);
                              } else {
                                _selectedRequests.remove(request);
                              }
                            }

                            refresh();
                          },
                        ),
                        row(request.name),
                        row(request.room.toString()),
                        row(request.birthday?.toLocal().formatDate() ?? "---"),
                        row(request.phone ?? "---"),
                        row(request.email ?? "---"),
                        row(request.createdAt.toLocal().toString()),
                        row(request.username ?? "---"),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.done_outlined),
                          label: Text("${AppLocale.Approve.getString(context)} (${_selectedRequests.length})"),
                          onPressed: _actionLock.locked ? null : () => _approveOrReject(RegisterRequest.approve),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.close_outlined),
                          label: Text("${AppLocale.Reject.getString(context)} (${_selectedRequests.length})"),
                          onPressed: _actionLock.locked ? null : () => _approveOrReject(RegisterRequest.reject),
                        ),
                      ],
                    ),
                    const SizedBox.square(dimension: 10),
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
                        FutureBuilder(
                          future: _countFuture,
                          builder: (context, _) {
                            return Text("${offset + 1}/${max(_offset, _offsetLimit) + 1}");
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_outlined),
                          onPressed: () {
                            if (_offset < _offsetLimit) {
                              offset++;
                            }
                            refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_outlined),
                          onPressed: () {
                            offset = 0;
                            refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_outlined),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: Text(AppLocale.Search.getString(context)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Form(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            controller: _userSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              label: Text(AppLocale.Fullname.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context);
                                              offset = 0;
                                            },
                                            validator: (value) => nameValidator(context, required: false, value: value),
                                          ),
                                          TextFormField(
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            controller: _roomSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              label: Text(AppLocale.Room.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context);
                                              offset = 0;
                                            },
                                            validator: (value) => roomValidator(context, required: false, value: value),
                                          ),
                                          const SizedBox.square(dimension: 10),
                                          TextButton.icon(
                                            icon: const Icon(Icons.done_outlined),
                                            label: Text(AppLocale.Search.getString(context)),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              offset = 0;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox.square(dimension: 5),
                    _notification,
                    const SizedBox.square(dimension: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                            width: max(mediaQuery.size.width, 1000),
                            padding: const EdgeInsets.all(5),
                            child: Table(children: rows),
                          ),
                        ),
                      ),
                    ),
                  ],
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
