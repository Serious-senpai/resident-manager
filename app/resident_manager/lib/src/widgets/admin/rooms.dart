import "dart:async";
import "dart:io";
import "dart:math";

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
  RoomsPageState createState() => RoomsPageState();
}

class RoomsPageState extends AbstractCommonState<RoomsPage> with CommonStateMixin<RoomsPage> {
  List<Room> _rooms = [];

  Future<int?>? _queryFuture;
  Future<int?>? _countFuture;

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

  bool get _searching => _roomSearch.text.isNotEmpty || _floorSearch.text.isNotEmpty;

  Future<int?> _query() async {
    try {
      final result = await Room.query(
        state: state,
        offset: DB_PAGINATION_QUERY * offset,
        room: int.tryParse(_roomSearch.text),
        floor: int.tryParse(_floorSearch.text),
      );

      final data = result.data;
      if (data != null) {
        _rooms = data;
      }

      return result.code;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
        return null;
      }

      rethrow;
    } finally {
      refresh();
    }
  }

  Future<int?> _count() async {
    try {
      final result = await Room.count(
        state: state,
        room: int.tryParse(_roomSearch.text),
        floor: int.tryParse(_floorSearch.text),
      );

      final data = result.data;
      if (data != null) {
        _offsetLimit = (data + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1;
      } else {
        _offsetLimit = offset;
      }

      return result.code;
    } catch (e) {
      _offsetLimit = offset;
      if (e is SocketException || e is TimeoutException) {
        await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
        return null;
      }

      rethrow;
    } finally {
      refresh();
    }
  }

  final _horizontalController = ScrollController();

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _queryFuture ??= _query();
    _countFuture ??= _count();

    return Scaffold(
      key: scaffoldKey,
      appBar: createAppBar(context, title: AppLocale.RoomsList.getString(context)),
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
                      headerCeil(AppLocale.Search.getString(context)),
                    ],
                  ),
                ];

                for (final room in _rooms) {
                  rows.add(
                    TableRow(
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
                          child: HoverContainer(
                            onHover: Colors.grey.shade200,
                            child: GestureDetector(
                              onTap: () async {
                                state.extras["room-search"] = room;
                                await Navigator.pushReplacementNamed(context, ApplicationRoute.adminResidentsPage);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("→"),
                              ),
                            ),
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
                            _searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                            style: TextStyle(decoration: _searching ? TextDecoration.underline : null),
                          ),
                          onPressed: () async {
                            final roomSearch = _roomSearch.text;
                            final floorSearch = _floorSearch.text;
                            final submitted = await showDialog(
                              context: context,
                              builder: (context) => SimpleDialog(
                                contentPadding: const EdgeInsets.all(10),
                                title: Text(AppLocale.Search.getString(context)),
                                children: [
                                  Form(
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
                                            Navigator.pop(context, true);
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
                                                  _roomSearch.clear();
                                                  _floorSearch.clear();

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
                                ],
                              ),
                            );

                            if (submitted == null) {
                              // Dialog dismissed. Restore field values
                              _roomSearch.text = roomSearch;
                              _floorSearch.text = floorSearch;
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox.square(dimension: 5),
                    Expanded(
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
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
                    Text((code == null ? AppLocale.ConnectionError : AppLocale.errorMessage(code)).getString(context)),
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
