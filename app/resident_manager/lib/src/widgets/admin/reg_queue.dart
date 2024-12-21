import "dart:async";
import "dart:io";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:data_table_2/data_table_2.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
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
        room: int.tryParse(_state.room),
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
  final selected = <RegisterRequest>{};

  static final _orderByMapping = [
    "name",
    "room",
    null,
    null,
    null,
    "id",
    "username",
  ];

  int _sortIndex = 5;
  int? get sortIndex => _orderByMapping[_sortIndex] == null ? null : _sortIndex;
  set sortIndex(int? value) {
    if (value != null) {
      assert(_orderByMapping[_sortIndex] != null);
      _sortIndex = value;
    }
  }

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
        room: int.tryParse(_state.room),
        username: _state.username,
        orderBy: _orderByMapping[_sortIndex],
        ascending: ascending,
      );

      final data = result.data;
      if (data != null) {
        selected.clear();
        requests.clear();
        requests.addAll(data);
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
  String name = "";
  String room = "";
  String username = "";

  bool get searching => name.isNotEmpty || room.isNotEmpty || username.isNotEmpty;

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

  final _horizontalScroll = ScrollController();

  @override
  CommonScaffold<RegisterQueuePage> build(BuildContext context) {
    return CommonScaffold(
      widgetState: this,
      title: Text(AppLocale.RegisterQueue.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(5),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                AdminMonitorWidget(
                  state: state,
                  pushNamed: Navigator.pushReplacementNamed,
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
                    FutureBuilder(
                      future: pagination.future,
                      initialData: pagination.lastData,
                      builder: (context, _) => PaginationButton(
                        offset: pagination.offset,
                        offsetLimit: pagination.offsetLimit,
                        setOffset: (p) {
                          pagination.offset = p;
                          reload();
                        },
                      ),
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
                      setOffset: (value) => pagination.offset = value,
                      reload: reload,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: Center(child: _notification)),
        FutureBuilder(
          future: queryLoader.future,
          initialData: queryLoader.lastData,
          builder: (context, _) {
            if (queryLoader.isLoading) {
              return const SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: LoadingIndicator(),
                ),
              );
            }

            final code = queryLoader.lastData;
            if (code != 0) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: ErrorIndicator(errorCode: code, callback: reload),
                ),
              );
            }

            void onSort(int column, bool ascending) {
              queryLoader.sortIndex = column;
              queryLoader.ascending = ascending;
              reload();
            }

            return SliverLayoutBuilder(
              builder: (context, constraints) => SliverToBoxAdapter(
                child: SizedBox(
                  height: constraints.remainingPaintExtent,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DataTable2(
                      columns: [
                        DataColumn2(label: Text(AppLocale.Fullname.getString(context)), size: ColumnSize.L, onSort: onSort),
                        DataColumn2(label: Text(AppLocale.Room.getString(context)), size: ColumnSize.S, onSort: onSort),
                        DataColumn2(label: Text(AppLocale.DateOfBirth.getString(context))),
                        DataColumn2(label: Text(AppLocale.Phone.getString(context))),
                        DataColumn2(label: Text(AppLocale.Email.getString(context)), size: ColumnSize.L),
                        DataColumn2(label: Text(AppLocale.CreationTime.getString(context)), size: ColumnSize.L, onSort: onSort),
                        DataColumn2(label: Text(AppLocale.Username.getString(context)), size: ColumnSize.L, onSort: onSort),
                      ],
                      columnSpacing: 5,
                      fixedTopRows: 1,
                      horizontalScrollController: _horizontalScroll,
                      minWidth: 1200,
                      rows: List<DataRow2>.from(
                        queryLoader.requests.map(
                          (r) => DataRow2(
                            cells: [
                              DataCell(Text(r.name)),
                              DataCell(Text(r.room.toString())),
                              DataCell(Text(r.birthday?.format("dd/mm/yyyy") ?? "---")),
                              DataCell(Text(r.phone ?? "---")),
                              DataCell(Text(r.email ?? "---")),
                              DataCell(Text(formatDateTime(r.createdAt.toLocal()))),
                              DataCell(Text(r.username ?? "---")),
                            ],
                            onSelectChanged: (selected) {
                              if (selected != null) {
                                if (selected) {
                                  queryLoader.selected.add(r);
                                } else {
                                  queryLoader.selected.remove(r);
                                }
                                refresh();
                              }
                            },
                            selected: queryLoader.selected.contains(r),
                          ),
                        ),
                      ),
                      showCheckboxColumn: true,
                      sortAscending: queryLoader.ascending,
                      sortColumnIndex: queryLoader.sortIndex,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
