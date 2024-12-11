import "dart:async";
import "dart:collection";
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
import "../../models/results.dart";
import "../../models/snowflake.dart";

class RegisterQueuePage extends StateAwareWidget {
  const RegisterQueuePage({super.key, required super.state});

  @override
  AbstractCommonState<RegisterQueuePage> createState() => _RegisterQueuePageState();
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int count = 0;
  int get offsetLimit => max(offset, (count + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1);

  final _RegisterQueuePageState _state;

  _Pagination(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await RegisterRequest.count(
        state: _state.state,
        name: _state.name,
        room: int.tryParse(_state.room ?? ""),
        username: _state.username,
      );

      final data = result.data;
      if (data != null) {
        count = data;
      }

      return result.code;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: _state.mounted ? AppLocale.ConnectionError.getString(_state.context) : AppLocale.ConnectionError);
        return null;
      }

      rethrow;
    } finally {
      _state.refresh();
    }
  }
}

class _QueryLoader extends FutureHolder<int?> {
  final requests = <RegisterRequest>[];
  final selected = SplayTreeSet<RegisterRequest>((k1, k2) => k1.id.compareTo(k2.id));

  String orderBy = "id";
  bool ascending = false;

  final _RegisterQueuePageState _state;

  _QueryLoader(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await RegisterRequest.query(
        state: _state.state,
        offset: DB_PAGINATION_QUERY * _state.pagination.offset,
        name: _state.name,
        room: int.tryParse(_state.room ?? ""),
        username: _state.username,
        orderBy: orderBy,
        ascending: ascending,
      );

      final data = result.data;
      if (data != null) {
        requests.clear();
        requests.addAll(data);
        requests.removeWhere(selected.contains);
        requests.addAll(selected);
      }

      return result.code;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: _state.mounted ? AppLocale.ConnectionError.getString(_state.context) : AppLocale.ConnectionError);
        return null;
      }

      rethrow;
    } finally {
      _state.refresh();
    }
  }
}

class _RegisterQueuePageState extends AbstractCommonState<RegisterQueuePage> with CommonScaffoldStateMixin<RegisterQueuePage> {
  String? name;
  String? room;
  String? username;

  bool get searching => name != null || room != null || username != null;

  _Pagination? _pagination;
  _Pagination get pagination => _pagination ??= _Pagination(this);

  _QueryLoader? _queryLoader;
  _QueryLoader get queryLoader => _queryLoader ??= _QueryLoader(this);

  Widget _notification = const SizedBox.shrink();

  final _actionLock = Lock();

  void reload() {
    pagination.reload();
    queryLoader.reload();
    refresh();
  }

  Future<void> _approveOrReject(Future<Result<void>?> Function({required Iterable<Snowflake> objects, required ApplicationState state}) coro) async {
    await _actionLock.run(
      () async {
        _notification = Builder(
          builder: (context) => Text(
            AppLocale.Loading.getString(context),
            style: const TextStyle(color: Colors.blue),
          ),
        );
        refresh();

        try {
          final result = await coro(state: state, objects: queryLoader.selected);
          if (result == null) {
            queryLoader.selected.clear();
            _notification = const SizedBox.shrink();
          } else {
            _notification = Builder(
              builder: (context) => Text(
                AppLocale.errorMessage(result.code).getString(context),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
        } catch (e) {
          await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
          _notification = Builder(
            builder: (context) => Text(
              AppLocale.ConnectionError.getString(context),
              style: const TextStyle(color: Colors.red),
            ),
          );

          if (!(e is SocketException || e is TimeoutException)) {
            rethrow;
          }
        } finally {
          reload();
        }
      },
    );
  }

  @override
  CommonScaffold<RegisterQueuePage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.RegisterQueue.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: FutureBuilder(
        future: queryLoader.future,
        initialData: queryLoader.lastData,
        builder: (context, _) {
          if (queryLoader.isLoading) {
            return const SliverCircularProgressFullScreen();
          }

          final code = queryLoader.lastData;
          if (code == 0) {
            TableCell headerCeil(String text, [String? newOrderBy]) {
              if (newOrderBy != null) {
                if (queryLoader.orderBy == newOrderBy) {
                  text += queryLoader.ascending ? " ▴" : " ▾";
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
                        if (newOrderBy == queryLoader.orderBy) {
                          queryLoader.ascending = !queryLoader.ascending;
                        } else {
                          queryLoader.ascending = true;
                        }

                        queryLoader.orderBy = newOrderBy;
                        pagination.offset = 0;
                        reload();
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
                      value: queryLoader.selected.containsAll(queryLoader.requests),
                      onChanged: (state) {
                        if (state != null) {
                          if (state) {
                            queryLoader.selected.addAll(queryLoader.requests);
                          } else {
                            queryLoader.selected.removeAll(queryLoader.requests);
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
                  headerCeil(AppLocale.CreationTime.getString(context), "id"),
                  headerCeil(AppLocale.Username.getString(context), "username"),
                ],
              ),
            ];

            for (final request in queryLoader.requests) {
              rows.add(
                TableRow(
                  children: [
                    Checkbox.adaptive(
                      value: queryLoader.selected.contains(request),
                      onChanged: (state) {
                        if (state != null) {
                          if (state) {
                            queryLoader.selected.add(request);
                          } else {
                            queryLoader.selected.remove(request);
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
                        child: Text(request.birthday?.format("dd/mm/yyyy") ?? "---"),
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

            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(5),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AdminMonitorWidget(
                          state: state,
                          pushNamed: pushNamedAndRefresh,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.done_outlined),
                              label: Text("${AppLocale.Approve.getString(context)} (${queryLoader.selected.length})"),
                              onPressed: () async {
                                if (!_actionLock.locked && queryLoader.selected.isNotEmpty) {
                                  final fmt = queryLoader.selected.length == 1 ? AppLocale.Approve1RegistrationRequest : AppLocale.ApproveNRegistrationRequests;
                                  final content = fmt.getString(context).replaceFirst("{n}", queryLoader.selected.length.toString());

                                  final confirm = await showConfirmDialog(
                                    context: context,
                                    title: Text(AppLocale.Confirm.getString(context)),
                                    content: Text(content),
                                  );

                                  if (confirm) {
                                    _approveOrReject(RegisterRequest.approve);
                                  }
                                }
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.close_outlined),
                              label: Text("${AppLocale.Reject.getString(context)} (${queryLoader.selected.length})"),
                              onPressed: () async {
                                if (!_actionLock.locked && queryLoader.selected.isNotEmpty) {
                                  final fmt = queryLoader.selected.length == 1 ? AppLocale.Reject1RegistrationRequest : AppLocale.RejectNRegistrationRequests;
                                  final content = fmt.getString(context).replaceFirst("{n}", queryLoader.selected.length.toString());

                                  final confirm = await showConfirmDialog(
                                    context: context,
                                    title: Text(AppLocale.Confirm.getString(context)),
                                    content: Text(content),
                                  );

                                  if (confirm) {
                                    _approveOrReject(RegisterRequest.reject);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_outlined),
                              onPressed: () {
                                if (pagination.offset > 0) {
                                  pagination.offset--;
                                  reload();
                                }
                              },
                            ),
                            FutureBuilder(
                              future: pagination.future,
                              builder: (context, _) {
                                final offset = pagination.offset, offsetLimit = pagination.offsetLimit;
                                return Text("${offset + 1}/${max(offset, offsetLimit) + 1}");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_outlined),
                              onPressed: () {
                                if (pagination.offset < pagination.offsetLimit) {
                                  pagination.offset++;
                                  reload();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_outlined),
                              onPressed: () {
                                pagination.offset = 0;
                                reload();
                              },
                            ),
                            AdminAccountSearchButton(
                              getName: () => name,
                              getRoom: () => room,
                              getUsername: () => username,
                              setName: (value) => name = value,
                              setRoom: (value) => room = value,
                              setUsername: (value) => username = value,
                              getSearching: () => searching,
                              setPageOffset: (value) => pagination.offset = value,
                              reload: reload,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: Center(child: _notification)),
                SliverPadding(
                  padding: const EdgeInsets.all(5),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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

          return SliverErrorFullScreen(errorCode: code, callback: reload);
        },
      ),
    );
  }
}
