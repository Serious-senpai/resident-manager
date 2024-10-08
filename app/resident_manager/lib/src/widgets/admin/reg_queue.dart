import "dart:async";
import "dart:io";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../utils.dart";
import "../../config.dart";
import "../../state.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/reg_request.dart";
import "../../models/snowflake.dart";

class RegisterQueuePage extends StateAwareWidget {
  const RegisterQueuePage({super.key, required super.state});

  @override
  RegisterQueuePageState createState() => RegisterQueuePageState();
}

class RegisterQueuePageState extends AbstractCommonState<RegisterQueuePage> with CommonStateMixin<RegisterQueuePage> {
  List<RegisterRequest> _requests = [];

  Future<bool>? _queryFuture;
  Future<bool>? _countFuture;
  Widget _notification = const SizedBox.square(dimension: 0);

  final _selected = <RegisterRequest>{};
  final _actionLock = Lock();

  final _nameSearch = TextEditingController();
  final _roomSearch = TextEditingController();
  final _usernameSearch = TextEditingController();
  String? orderBy;
  bool ascending = true;

  int _offset = 0;
  int _offsetLimit = 0;
  int get offset => _offset;
  set offset(int value) {
    _offset = value;
    _queryFuture = null;
    _countFuture = null;
    refresh();
  }

  bool get searching => _nameSearch.text.isNotEmpty || _roomSearch.text.isNotEmpty || _usernameSearch.text.isNotEmpty;

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
          success = await coro(state: state, objects: _selected);
        } catch (e) {
          if (e is SocketException || e is TimeoutException) {
            await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
          } else {
            rethrow;
          }
        }

        if (success) {
          _notification = const SizedBox.square(dimension: 0);
          _selected.clear();
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

  Future<bool> query() async {
    try {
      _requests = await RegisterRequest.query(
        state: state,
        offset: DB_PAGINATION_QUERY * offset,
        name: _nameSearch.text,
        room: int.tryParse(_roomSearch.text),
        username: _usernameSearch.text,
        orderBy: orderBy,
        ascending: ascending,
      );

      refresh();
      return true;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
        return false;
      }

      rethrow;
    }
  }

  Future<bool> count() async {
    try {
      final value = await RegisterRequest.count(
        state: state,
        name: _nameSearch.text,
        room: int.tryParse(_roomSearch.text),
        username: _usernameSearch.text,
      );
      if (value == null) {
        _offsetLimit = offset;
        return false;
      }

      _offsetLimit = (value + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1;
      return true;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
        _offsetLimit = offset;
        return false;
      }

      rethrow;
    }
  }

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _queryFuture ??= query();
    _countFuture ??= count();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
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
                    const SizedBox.square(dimension: 5),
                    Text(AppLocale.Loading.getString(context)),
                  ],
                ),
              );

            case ConnectionState.done:
              final success = snapshot.data ?? false;
              if (success) {
                TableCell headerCeil(String text, [String? newOrderBy]) {
                  if (newOrderBy != null) {
                    if (orderBy == newOrderBy) {
                      text += ascending ? " ▴" : " ▾";
                    } else {
                      text += " ▴▾";
                    }
                  }

                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: GestureDetector(
                        onTap: () {
                          if (newOrderBy != null) {
                            if (newOrderBy == orderBy) {
                              ascending = !ascending;
                            } else {
                              ascending = true;
                            }

                            orderBy = newOrderBy;
                            offset = 0;
                          }
                        },
                        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }

                final rows = [
                  TableRow(
                    decoration: const BoxDecoration(border: BorderDirectional(bottom: BorderSide(width: 1))),
                    children: [
                      TableCell(
                        child: Checkbox.adaptive(
                          value: _selected.containsAll(_requests),
                          onChanged: (state) {
                            if (state != null) {
                              if (state) {
                                _selected.addAll(_requests);
                              } else {
                                _selected.removeAll(_requests);
                              }
                            }

                            refresh();
                          },
                        ),
                      ),
                      headerCeil(AppLocale.Fullname.getString(context), "name"),
                      headerCeil(AppLocale.Room.getString(context), "room"),
                      headerCeil(AppLocale.DateOfBirth.getString(context)),
                      headerCeil(AppLocale.Phone.getString(context)),
                      headerCeil(AppLocale.Email.getString(context)),
                      headerCeil(AppLocale.CreationTime.getString(context), "request_id"),
                      headerCeil(AppLocale.Username.getString(context), "username"),
                    ],
                  ),
                ];

                for (final request in _requests) {
                  rows.add(
                    TableRow(
                      children: [
                        Checkbox.adaptive(
                          value: _selected.contains(request),
                          onChanged: (state) {
                            if (state != null) {
                              if (state) {
                                _selected.add(request);
                              } else {
                                _selected.remove(request);
                              }
                            }

                            refresh();
                          },
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.name),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.room.toString()),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.birthday?.toLocal().formatDate() ?? "---"),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.phone ?? "---"),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.email ?? "---"),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.createdAt.toLocal().toString()),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(request.username ?? "---"),
                          ),
                        ),
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
                          label: Text("${AppLocale.Approve.getString(context)} (${_selected.length})"),
                          onPressed: _actionLock.locked || _selected.isEmpty ? null : () => _approveOrReject(RegisterRequest.approve),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.close_outlined),
                          label: Text("${AppLocale.Reject.getString(context)} (${_selected.length})"),
                          onPressed: _actionLock.locked || _selected.isEmpty ? null : () => _approveOrReject(RegisterRequest.reject),
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
                        TextButton.icon(
                          icon: const Icon(Icons.search_outlined),
                          label: Text(
                            searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                            style: TextStyle(decoration: searching ? TextDecoration.underline : null),
                          ),
                          onPressed: () async {
                            final nameSearch = _nameSearch.text;
                            final roomSearch = _roomSearch.text;
                            final usernameSearch = _usernameSearch.text;
                            final submitted = await showDialog(
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
                                            controller: _nameSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              icon: const Icon(Icons.badge_outlined),
                                              label: Text(AppLocale.Fullname.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context, true);
                                              offset = 0;
                                            },
                                            validator: (value) => nameValidator(context, required: false, value: value),
                                          ),
                                          TextFormField(
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            controller: _roomSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              icon: const Icon(Icons.room_outlined),
                                              label: Text(AppLocale.Room.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context, true);
                                              offset = 0;
                                            },
                                            validator: (value) => roomValidator(context, required: false, value: value),
                                          ),
                                          TextFormField(
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            controller: _usernameSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              icon: const Icon(Icons.person_outline),
                                              label: Text(AppLocale.Username.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context, true);
                                              offset = 0;
                                            },
                                          ),
                                          const SizedBox.square(dimension: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.done_outlined),
                                                  label: Text(AppLocale.Search.getString(context)),
                                                  onPressed: () {
                                                    Navigator.pop(context, true);
                                                    offset = 0;
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.clear_outlined),
                                                  label: Text(AppLocale.ClearAll.getString(context)),
                                                  onPressed: () {
                                                    _nameSearch.clear();
                                                    _roomSearch.clear();
                                                    _usernameSearch.clear();

                                                    Navigator.pop(context, true);
                                                    offset = 0;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (submitted == null) {
                              // Dialog dismissed. Restore field values
                              _nameSearch.text = nameSearch;
                              _roomSearch.text = roomSearch;
                              _usernameSearch.text = usernameSearch;
                            }
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

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox.square(
                      dimension: 50,
                      child: Icon(Icons.highlight_off_outlined),
                    ),
                    const SizedBox.square(dimension: 5),
                    Text(AppLocale.ConnectionError.getString(context)),
                  ],
                ),
              );
          }
        },
      ),
      drawer: createDrawer(context),
    );
  }
}
