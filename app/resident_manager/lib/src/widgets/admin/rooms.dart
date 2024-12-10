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
import "../../routes.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/rooms.dart";

class RoomsPage extends StateAwareWidget {
  const RoomsPage({super.key, required super.state});

  @override
  AbstractCommonState<RoomsPage> createState() => _RoomsPageState();
}

class _SearchField {
  final room = TextEditingController();
  final floor = TextEditingController();

  bool get searching => room.text.isNotEmpty || floor.text.isNotEmpty;

  void dispose() {
    room.dispose();
    floor.dispose();
  }
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int offsetLimit = 0;

  final _RoomsPageState _state;

  _Pagination(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await Room.count(
        state: _state.state,
        room: int.tryParse(_state.search.room.text),
        floor: int.tryParse(_state.search.floor.text),
      );

      final data = result.data;
      if (data != null) {
        offsetLimit = (data + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1;
      } else {
        offsetLimit = offset;
      }

      return result.code;
    } catch (e) {
      offsetLimit = offset;
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
        room: int.tryParse(_state.search.room.text),
        floor: int.tryParse(_state.search.floor.text),
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
  final search = _SearchField();

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

  @override
  void dispose() {
    super.dispose();
    search.dispose();
  }

  @override
  CommonScaffold<RoomsPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.RoomsList.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: FutureBuilder(
        future: queryLoader.future,
        initialData: queryLoader.lastData,
        builder: (context, snapshot) {
          if (queryLoader.isLoading) {
            return const SliverCircularProgressFullScreen();
          }

          final code = snapshot.data;
          if (code == 0) {
            TableCell headerCeil(String text) {
              return TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }

            final rows = [
              TableRow(
                decoration: const BoxDecoration(border: BorderDirectional(bottom: BorderSide(width: 1))),
                children: [
                  headerCeil(AppLocale.Room.getString(context)),
                  headerCeil(AppLocale.Floor.getString(context)),
                  headerCeil(AppLocale.Area1.getString(context)),
                  headerCeil(AppLocale.MotorbikesCount.getString(context)),
                  headerCeil(AppLocale.CarsCount.getString(context)),
                  headerCeil(AppLocale.ResidentsCount.getString(context)),
                  headerCeil(AppLocale.Option.getString(context)),
                ],
              ),
              ...List<TableRow>.from(
                queryLoader.rooms.map(
                  (room) => TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.room.toString()),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.floor.toString()),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.area?.toString() ?? "---"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.motorbike?.toString() ?? "---"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.car?.toString() ?? "---"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(room.residents.toString()),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
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
                                  final roomController = TextEditingController(text: room.room.toString());
                                  final areaController = TextEditingController(text: room.area?.toString());
                                  final motorbikeController = TextEditingController(text: room.motorbike?.toString());
                                  final carController = TextEditingController(text: room.car?.toString());

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
                                                  room: room.room,
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
                                        final result = await room.delete(state: state);
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
                      ),
                    ],
                  ),
                ),
              ),
            ];

            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(5),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AdminMonitorWidget(state: state),
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
                              icon: Icon(search.searching ? Icons.search_outlined : Icons.search_off_outlined),
                              label: Text(
                                search.searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                                style: TextStyle(decoration: search.searching ? TextDecoration.underline : null),
                              ),
                              onPressed: () async {
                                // Save current values for restoration
                                final roomSearch = search.room.text;
                                final floorSearch = search.floor.text;

                                final formKey = GlobalKey<FormState>();

                                void onSubmit(BuildContext context) {
                                  Navigator.pop(context, true);
                                  pagination.offset = 0;
                                  reload();
                                }

                                final submitted = await showDialog(
                                  context: context,
                                  builder: (context) => SimpleDialog(
                                    contentPadding: const EdgeInsets.all(10),
                                    title: Text(AppLocale.Search.getString(context)),
                                    children: [
                                      Form(
                                        key: formKey,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: search.room,
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.all(8.0),
                                                icon: const Icon(Icons.room_outlined),
                                                label: Text(AppLocale.Room.getString(context)),
                                              ),
                                              onFieldSubmitted: (_) => onSubmit(context),
                                              validator: (value) => roomValidator(context, required: false, value: value),
                                            ),
                                            TextFormField(
                                              controller: search.floor,
                                              decoration: InputDecoration(
                                                contentPadding: const EdgeInsets.all(8.0),
                                                icon: const Icon(Icons.apartment_outlined),
                                                label: Text(AppLocale.Floor.getString(context)),
                                              ),
                                              onFieldSubmitted: (_) => onSubmit(context),
                                            ),
                                            const SizedBox.square(dimension: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: TextButton.icon(
                                                    icon: const Icon(Icons.done_outlined),
                                                    label: Text(AppLocale.Search.getString(context)),
                                                    onPressed: () => onSubmit(context),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextButton.icon(
                                                    icon: const Icon(Icons.clear_outlined),
                                                    label: Text(AppLocale.ClearAll.getString(context)),
                                                    onPressed: () {
                                                      search.room.clear();
                                                      search.floor.clear();

                                                      onSubmit(context);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (submitted == null) {
                                  // Dialog dismissed. Restore field values
                                  search.room.text = roomSearch;
                                  search.floor.text = floorSearch;
                                }
                              },
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
