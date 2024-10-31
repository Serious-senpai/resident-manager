import "dart:async";
import "dart:collection";
import "dart:io";
import "dart:math";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:resident_manager/src/models/info.dart";

import "../common.dart";
import "../state.dart";
import "../../config.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/residents.dart";
import "../../models/rooms.dart";

class ResidentsPage extends StateAwareWidget {
  const ResidentsPage({super.key, required super.state});

  @override
  AbstractCommonState<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends AbstractCommonState<ResidentsPage> with CommonStateMixin<ResidentsPage> {
  List<Resident> _residents = [];

  Future<int?>? _queryFuture;
  Future<int?>? _countFuture;
  Widget _notification = const SizedBox.square(dimension: 0);

  final _selected = SplayTreeSet<Resident>((k1, k2) => k1.id.compareTo(k2.id));
  final _actionLock = Lock();

  final _nameSearch = TextEditingController();
  final _roomSearch = TextEditingController();
  final _usernameSearch = TextEditingController();
  String orderBy = "resident_id";
  bool ascending = false;

  int _offset = 0;
  int _offsetLimit = 0;
  int get offset => _offset;
  set offset(int value) {
    _offset = value;
    _queryFuture = null;
    _countFuture = null;
    refresh();
  }

  bool get _searching => _nameSearch.text.isNotEmpty || _roomSearch.text.isNotEmpty || _usernameSearch.text.isNotEmpty;

  Future<int?> _query() async {
    try {
      final result = await Resident.query(
        state: state,
        offset: DB_PAGINATION_QUERY * offset,
        name: _nameSearch.text,
        room: int.tryParse(_roomSearch.text),
        username: _usernameSearch.text,
        orderBy: orderBy,
        ascending: ascending,
      );

      final data = result.data;
      if (data != null) {
        _residents = data;
        _residents.removeWhere(_selected.contains);
        _residents.addAll(_selected);
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
      final result = await Resident.count(
        state: state,
        name: _nameSearch.text,
        room: int.tryParse(_roomSearch.text),
        username: _usernameSearch.text,
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

  Future<void> _deleteAccounts() async {
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
          if (await Resident.delete(state: state, objects: _selected)) {
            _selected.clear();
          }

          _notification = const SizedBox.square(dimension: 0);
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
          offset = 0;
        }
      },
    );
  }

  @override
  void initState() {
    final room = state.extras["room-search"] as Room?;
    if (room != null) {
      _roomSearch.text = room.room.toString();
      state.extras["room-search"] = null;
    }

    super.initState();
  }

  final _horizontalController = ScrollController();

  @override
  CommonScaffold<ResidentsPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _queryFuture ??= _query();
    _countFuture ??= _count();

    return CommonScaffold(
      state: this,
      title: Text(AppLocale.ResidentsList.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          value: _selected.containsAll(_residents),
                          onChanged: (state) {
                            if (state != null) {
                              if (state) {
                                _selected.addAll(_residents);
                              } else {
                                _selected.removeAll(_residents);
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
                      headerCeil(AppLocale.CreationTime.getString(context), "resident_id"),
                      headerCeil(AppLocale.Username.getString(context), "username"),
                      headerCeil(AppLocale.Option.getString(context)),
                    ],
                  ),
                  ...List<TableRow>.from(
                    _residents.map(
                      (resident) => TableRow(
                        children: [
                          Checkbox.adaptive(
                            value: _selected.contains(resident),
                            onChanged: (state) {
                              if (state != null) {
                                if (state) {
                                  _selected.add(resident);
                                } else {
                                  _selected.remove(resident);
                                }
                              }

                              refresh();
                            },
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.name),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.room.toString()),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.birthday?.toLocal().formatDate() ?? "---"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.phone ?? "---"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.email ?? "---"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.createdAt.toLocal().toString()),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(resident.username ?? "---"),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final nameController = TextEditingController(text: resident.name);
                                      final roomController = TextEditingController(text: resident.room.toString());
                                      final birthdayController = TextEditingController(text: resident.birthday?.toLocal().formatDate());
                                      final phoneController = TextEditingController(text: resident.phone);
                                      final emailController = TextEditingController(text: resident.email);

                                      final formKey = GlobalKey<FormState>();
                                      final submitted = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => SimpleDialog(
                                          contentPadding: const EdgeInsets.all(10),
                                          title: Text(AppLocale.EditPersonalInfo.getString(context)),
                                          children: [
                                            Form(
                                              key: formKey,
                                              autovalidateMode: AutovalidateMode.onUserInteraction,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  TextFormField(
                                                    controller: nameController,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.all(8.0),
                                                      label: FieldLabel(AppLocale.Fullname.getString(context), required: true),
                                                    ),
                                                    validator: (value) => nameValidator(context, required: true, value: value),
                                                  ),
                                                  TextFormField(
                                                    controller: roomController,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.all(8.0),
                                                      label: FieldLabel(AppLocale.Room.getString(context), required: true),
                                                    ),
                                                    validator: (value) => roomValidator(context, required: true, value: value),
                                                  ),
                                                  TextFormField(
                                                    controller: birthdayController,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.all(8.0),
                                                      label: FieldLabel(AppLocale.DateOfBirth.getString(context)),
                                                    ),
                                                    onTap: () async {
                                                      final birthday = await showDatePicker(
                                                        context: context,
                                                        initialDate: DateFormat.fromFormattedDate(birthdayController.text),
                                                        firstDate: DateTime.utc(1900),
                                                        lastDate: DateTime.now(),
                                                      );

                                                      if (birthday != null) {
                                                        birthdayController.text = birthday.toLocal().formatDate();
                                                      } else {
                                                        birthdayController.clear();
                                                      }
                                                    },
                                                    readOnly: true, // no need for validator
                                                  ),
                                                  TextFormField(
                                                    controller: phoneController,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.all(8.0),
                                                      label: FieldLabel(AppLocale.Phone.getString(context)),
                                                    ),
                                                    validator: (value) => phoneValidator(context, value: value),
                                                  ),
                                                  TextFormField(
                                                    controller: emailController,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.all(8.0),
                                                      label: FieldLabel(AppLocale.Email.getString(context)),
                                                    ),
                                                    validator: (value) => emailValidator(context, value: value),
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
                                                final result = await resident.update(
                                                  state: state,
                                                  info: PersonalInfo(
                                                    name: nameController.text,
                                                    room: int.parse(roomController.text),
                                                    birthday: birthdayController.text.isEmpty ? null : DateFormat.fromFormattedDate(birthdayController.text),
                                                    phone: phoneController.text,
                                                    email: emailController.text,
                                                  ),
                                                );

                                                if (result.code != 0) {
                                                  _notification = Builder(
                                                    builder: (context) => Text(
                                                      AppLocale.errorMessage(result.code).getString(context),
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                  );
                                                } else {
                                                  _notification = const SizedBox.square(dimension: 0);
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
                                                _queryFuture = null;
                                                refresh();
                                              }
                                            },
                                          );
                                        }
                                      }
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

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outlined),
                          label: Text("${AppLocale.DeleteAccount.getString(context)} (${_selected.length})"),
                          onPressed: _actionLock.locked || _selected.isEmpty ? null : _deleteAccounts,
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
                            _searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                            style: TextStyle(decoration: _searching ? TextDecoration.underline : null),
                          ),
                          onPressed: () async {
                            // Save current values for restoration
                            final nameSearch = _nameSearch.text;
                            final roomSearch = _roomSearch.text;
                            final usernameSearch = _usernameSearch.text;

                            final formKey = GlobalKey<FormState>();
                            final submitted = await showDialog<bool>(
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
                                          controller: _usernameSearch,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.all(8.0),
                                            icon: const Icon(Icons.person_outlined),
                                            label: Text(AppLocale.Username.getString(context)),
                                          ),
                                          onFieldSubmitted: (_) {
                                            Navigator.pop(context, true);
                                            offset = 0;
                                          },
                                          validator: (value) => usernameValidator(context, required: false, value: value),
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
                                                  if (formKey.currentState?.validate() ?? false) {
                                                    Navigator.pop(context, true);
                                                    offset = 0;
                                                  }
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
    );
  }
}
