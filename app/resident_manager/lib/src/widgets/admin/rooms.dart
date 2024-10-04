import "dart:async";
import "dart:io";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../../utils.dart";
import "../../core/config.dart";
import "../../core/translations.dart";
import "../../core/models/rooms.dart";

class RoomsPage extends StateAwareWidget {
  const RoomsPage({super.key, required super.state});

  @override
  RoomsPageState createState() => RoomsPageState();
}

class RoomsPageState extends AbstractCommonState<RoomsPage> with CommonStateMixin<RoomsPage> {
  List<Room> _rooms = [];

  Future<bool>? _queryFuture;
  Future<bool>? _countFuture;

  final _roomSearch = TextEditingController();
  final _floorSearch = TextEditingController();

  int _offset = 0;
  int _offsetLimit = 0;
  int get offset => _offset;
  set offset(int value) {
    _offset = value;
    _queryFuture = null;
    _countFuture = null;
    refresh();
  }

  bool get searching => _roomSearch.text.isNotEmpty || _floorSearch.text.isNotEmpty;

  Future<bool> query() async {
    try {
      _rooms = await Room.query(
        state: state,
        offset: DB_PAGINATION_QUERY * offset,
        room: int.tryParse(_roomSearch.text),
        floor: int.tryParse(_floorSearch.text),
      );

      refresh();
      return true;
    } catch (_) {
      await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
      return false;
    }
  }

  Future<bool> count() async {
    try {
      final value = await Room.count(
        state: state,
        room: int.tryParse(_roomSearch.text),
        floor: int.tryParse(_floorSearch.text),
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
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.menu_outlined),
        ),
        title: Text(AppLocale.RoomsList.getString(context)),
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
                TableCell header(String text) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }

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
                      header(AppLocale.Room.getString(context)),
                      header(AppLocale.Floor.getString(context)),
                      header(AppLocale.Area1.getString(context)),
                      header(AppLocale.MotorbikesCount.getString(context)),
                      header(AppLocale.CarsCount.getString(context)),
                    ],
                  ),
                ];

                for (final room in _rooms) {
                  rows.add(
                    TableRow(
                      children: [
                        row(room.room.toString()),
                        row(room.floor.toString()),
                        row(room.area.toString()),
                        row(room.motorbike.toString()),
                        row(room.car.toString()),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
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
                                            controller: _roomSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              icon: const Icon(Icons.room_outlined),
                                              label: Text(AppLocale.Room.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context);
                                              offset = 0;
                                            },
                                            validator: (value) => roomValidator(context, required: false, value: value),
                                          ),
                                          TextFormField(
                                            autovalidateMode: AutovalidateMode.onUserInteraction,
                                            controller: _floorSearch,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              icon: const Icon(Icons.apartment_outlined),
                                              label: Text(AppLocale.Floor.getString(context)),
                                            ),
                                            onFieldSubmitted: (_) {
                                              Navigator.pop(context);
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
                                                    Navigator.pop(context);
                                                    offset = 0;
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.clear_outlined),
                                                  label: Text(AppLocale.ClearAll.getString(context)),
                                                  onPressed: () {
                                                    _roomSearch.clear();
                                                    _floorSearch.clear();

                                                    Navigator.pop(context);
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
                          },
                        ),
                      ],
                    ),
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
