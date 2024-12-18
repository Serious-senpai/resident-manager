import "dart:async";
import "dart:io";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:data_table_2/data_table_2.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../utils.dart";
import "../../config.dart";
import "../../routes.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/rooms.dart";

class RoomsPage extends StateAwareWidget {
  const RoomsPage({super.key, required super.state});

  @override
  AbstractCommonState<RoomsPage> createState() => _RoomsPageState();
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int count = 0;
  int get offsetLimit => max(offset, (count + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1);

  final _RoomsPageState _state;

  _Pagination(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await Room.count(
        state: _state.state,
        room: int.tryParse(_state.room),
        floor: int.tryParse(_state.floor),
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
  final rooms = <Room>[];

  final _RoomsPageState _state;

  _QueryLoader(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await Room.query(
        state: _state.state,
        offset: DB_PAGINATION_QUERY * _state.pagination.offset,
        room: int.tryParse(_state.room),
        floor: int.tryParse(_state.floor),
      );

      final data = result.data;
      if (data != null) {
        rooms.clear();
        rooms.addAll(data);
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

class _RoomsPageState extends AbstractCommonState<RoomsPage> with CommonScaffoldStateMixin<RoomsPage> {
  String room = "";
  String floor = "";

  bool get searching => room.isNotEmpty || floor.isNotEmpty;

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

  final _horizontalScroll = ScrollController();

  @override
  CommonScaffold<RoomsPage> build(BuildContext context) {
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
                  pushNamed: pushNamedAndRefresh,
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
                    TextButton.icon(
                      icon: Icon(searching ? Icons.search_outlined : Icons.search_off_outlined),
                      label: Text(
                        searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                        style: TextStyle(decoration: searching ? TextDecoration.underline : null),
                      ),
                      onPressed: () async {
                        // Save current values for restoration
                        final roomController = TextEditingController(text: room);
                        final floorController = TextEditingController(text: floor);
                        final formKey = GlobalKey<FormState>();

                        void onSubmit(BuildContext context) {
                          if (formKey.currentState?.validate() ?? false) {
                            room = roomController.text;
                            floor = floorController.text;
                            pagination.offset = 0;

                            Navigator.pop(context, true);
                            reload();
                          }
                        }

                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(AppLocale.Search.getString(context)),
                            content: Form(
                              key: formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: roomController,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      icon: const Icon(Icons.room_outlined),
                                      label: Text(AppLocale.Room.getString(context)),
                                    ),
                                    onFieldSubmitted: (_) => onSubmit(context),
                                    validator: (value) => roomValidator(context, required: false, value: value),
                                  ),
                                  TextFormField(
                                    controller: floorController,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      icon: const Icon(Icons.apartment_outlined),
                                      label: Text(AppLocale.Floor.getString(context)),
                                    ),
                                    onFieldSubmitted: (_) => onSubmit(context),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                icon: const Icon(Icons.done_outlined),
                                label: Text(AppLocale.Search.getString(context)),
                                onPressed: () => onSubmit(context),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.clear_outlined),
                                label: Text(AppLocale.ClearAll.getString(context)),
                                onPressed: () {
                                  roomController.clear();
                                  floorController.clear();

                                  onSubmit(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
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

            return SliverLayoutBuilder(
              builder: (context, constraints) => SliverToBoxAdapter(
                child: SizedBox(
                  height: constraints.remainingPaintExtent,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DataTable2(
                      columns: [
                        DataColumn2(label: Text(AppLocale.Room.getString(context))),
                        DataColumn2(label: Text(AppLocale.Floor.getString(context))),
                        DataColumn2(label: Text(AppLocale.Area1.getString(context)), numeric: true),
                        DataColumn2(label: Text(AppLocale.MotorbikesCount.getString(context)), numeric: true),
                        DataColumn2(label: Text(AppLocale.CarsCount.getString(context)), numeric: true),
                        DataColumn2(label: Text(AppLocale.ResidentsCount.getString(context)), numeric: true),
                        DataColumn2(label: Text(AppLocale.Option.getString(context))),
                      ],
                      fixedTopRows: 1,
                      horizontalScrollController: _horizontalScroll,
                      minWidth: 1200,
                      rows: List<DataRow2>.from(
                        queryLoader.rooms.map(
                          (r) => DataRow2(
                            cells: [
                              DataCell(Text(r.room.toString())),
                              DataCell(Text(r.floor.toString())),
                              DataCell(Text(r.area?.toString() ?? "---")),
                              DataCell(Text(r.motorbike?.toString() ?? "---")),
                              DataCell(Text(r.car?.toString() ?? "---")),
                              DataCell(Text(r.residents.toString())),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.search_outlined),
                                      onPressed: () async {
                                        state.extras["room-search"] = room;
                                        await pushNamedAndRefresh(context, ApplicationRoute.adminResidentsPage);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () async {
                                        final roomController = TextEditingController(text: r.room.toString());
                                        final areaController = TextEditingController(text: r.area?.toString());
                                        final motorbikeController = TextEditingController(text: r.motorbike?.toString());
                                        final carController = TextEditingController(text: r.car?.toString());

                                        final formKey = GlobalKey<FormState>();
                                        final submitted = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => SimpleDialog(
                                            contentPadding: const EdgeInsets.all(10),
                                            title: Text(AppLocale.EditRoomInfo.getString(context)),
                                            children: [
                                              Form(
                                                key: formKey,
                                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    TextFormField(
                                                      controller: roomController,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.all(8.0),
                                                        label: FieldLabel(
                                                          AppLocale.Room.getString(context),
                                                          style: const TextStyle(color: Colors.black),
                                                          required: true,
                                                        ),
                                                      ),
                                                      enabled: false,
                                                      validator: (value) => roomValidator(context, required: true, value: value),
                                                    ),
                                                    TextFormField(
                                                      controller: areaController,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.all(8.0),
                                                        label: FieldLabel(
                                                          AppLocale.Area1.getString(context),
                                                          style: const TextStyle(color: Colors.black),
                                                          required: true,
                                                        ),
                                                      ),
                                                      validator: (value) => roomAreaValidator(context, required: true, value: value),
                                                    ),
                                                    TextFormField(
                                                      controller: motorbikeController,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.all(8.0),
                                                        label: FieldLabel(
                                                          AppLocale.MotorbikesCount.getString(context),
                                                          style: const TextStyle(color: Colors.black),
                                                          required: true,
                                                        ),
                                                      ),
                                                      validator: (value) => motorbikesCountValidator(context, required: true, value: value),
                                                    ),
                                                    TextFormField(
                                                      controller: carController,
                                                      decoration: InputDecoration(
                                                        contentPadding: const EdgeInsets.all(8.0),
                                                        label: FieldLabel(
                                                          AppLocale.CarsCount.getString(context),
                                                          style: const TextStyle(color: Colors.black),
                                                          required: true,
                                                        ),
                                                      ),
                                                      validator: (value) => carsCountValidator(context, required: true, value: value),
                                                    ),
                                                    const SizedBox.square(dimension: 10),
                                                    Container(
                                                      padding: const EdgeInsets.all(5),
                                                      width: double.infinity,
                                                      child: TextButton.icon(
                                                        icon: const Icon(Icons.done_outlined),
                                                        label: Text(AppLocale.Confirm.getString(context)),
                                                        onPressed: () {
                                                          if (formKey.currentState?.validate() ?? false) {
                                                            Navigator.pop(context, true);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (submitted != null) {
                                          final check = formKey.currentState?.validate() ?? false;
                                          if (check) {
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
                                                  final result = await RoomData.update(
                                                    state: state,
                                                    rooms: [
                                                      RoomData(
                                                        room: r.room,
                                                        area: double.parse(areaController.text),
                                                        motorbike: int.parse(motorbikeController.text),
                                                        car: int.parse(carController.text),
                                                      ),
                                                    ],
                                                  );

                                                  if (result != null) {
                                                    _notification = Builder(
                                                      builder: (context) => Text(
                                                        AppLocale.errorMessage(result.code).getString(context),
                                                        style: const TextStyle(color: Colors.red),
                                                      ),
                                                    );
                                                  } else {
                                                    _notification = const SizedBox.shrink();
                                                  }
                                                } catch (e) {
                                                  await showToastSafe(msg: context.mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
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
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outlined),
                                      onPressed: () async {
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
                                              final result = await r.delete(state: state);
                                              if (result != null) {
                                                _notification = Builder(
                                                  builder: (context) => Text(
                                                    AppLocale.errorMessage(result.code).getString(context),
                                                    style: const TextStyle(color: Colors.red),
                                                  ),
                                                );
                                              } else {
                                                _notification = const SizedBox.shrink();
                                              }
                                            } catch (e) {
                                              await showToastSafe(msg: context.mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
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
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
