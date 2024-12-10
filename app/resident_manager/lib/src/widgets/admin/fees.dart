import "dart:async";
import "dart:collection";
import "dart:io";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../utils.dart";
import "../../config.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/fee.dart";

class FeeListPage extends StateAwareWidget {
  const FeeListPage({super.key, required super.state});

  @override
  AbstractCommonState<FeeListPage> createState() => _FeeListPageState();
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int count = 0;
  int get offsetLimit => max(offset, (count + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1);

  final _FeeListPageState _state;

  _Pagination(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await Fee.count(
        state: _state.state,
        // Query does not support filtering by time yet
        createdAfter: epoch,
        createdBefore: DateTime.now(),
        name: _state.queryLoader.name,
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
  final fees = <Fee>[];
  final selected = SplayTreeSet<Fee>((k1, k2) => k1.id.compareTo(k2.id));

  DateTime? createdAfter;
  DateTime? createdBefore;
  String? name;

  bool get searching => name != null;

  int orderBy = -1;
  bool ascending = false;

  final _FeeListPageState _state;

  _QueryLoader(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await Fee.query(
        state: _state.state,
        offset: DB_PAGINATION_QUERY * _state.pagination.offset,
        createdAfter: createdAfter ?? epoch,
        createdBefore: createdBefore ?? DateTime.now(),
        name: name,
        orderBy: orderBy,
        ascending: ascending,
      );

      final data = result.data;
      if (data != null) {
        fees.clear();
        fees.addAll(data);
        fees.removeWhere(selected.contains);
        fees.addAll(selected);
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

class _FeeListPageState extends AbstractCommonState<FeeListPage> with CommonScaffoldStateMixin<FeeListPage> {
  _Pagination? _pagination;
  _Pagination get pagination => _pagination ??= _Pagination(this);

  _QueryLoader? _queryLoader;
  _QueryLoader get queryLoader => _queryLoader ??= _QueryLoader(this);

  void reload() {
    pagination.reload();
    queryLoader.reload();
    refresh();
  }

  @override
  CommonScaffold<FeeListPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.FeeList.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: FutureBuilder(
        future: queryLoader.future,
        initialData: queryLoader.lastData,
        builder: (context, _) {
          if (queryLoader.isLoading) {
            return const SliverCircularProgressFullScreen();
          }

          final code = queryLoader.lastData;
          if (code == 0) {
            TableCell headerCeil(String text, [int? newOrderBy]) {
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
                      value: queryLoader.selected.containsAll(queryLoader.fees),
                      onChanged: (state) {
                        if (state != null) {
                          if (state) {
                            queryLoader.selected.addAll(queryLoader.fees);
                          } else {
                            queryLoader.selected.removeAll(queryLoader.fees);
                          }
                        }

                        refresh();
                      },
                    ),
                  ),
                  headerCeil(AppLocale.Fee.getString(context), 2),
                  headerCeil(AppLocale.Deadline.getString(context), 8),
                  headerCeil(AppLocale.Description.getString(context)),
                  headerCeil(AppLocale.FeeLowerBound.getString(context), 3),
                  headerCeil(AppLocale.FeeUpperBound.getString(context), 4),
                ],
              ),
            ];

            for (final fee in queryLoader.fees) {
              rows.add(
                TableRow(
                  children: [
                    Checkbox.adaptive(
                      value: queryLoader.selected.contains(fee),
                      onChanged: (state) {
                        if (state != null) {
                          if (state) {
                            queryLoader.selected.add(fee);
                          } else {
                            queryLoader.selected.remove(fee);
                          }
                        }

                        refresh();
                      },
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(fee.name),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(fee.deadline.toString()),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(fee.description),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(fee.lower.round().toString()),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(fee.upper.round().toString()),
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
                              icon: Icon(queryLoader.searching ? Icons.search_outlined : Icons.search_off_outlined),
                              label: Text(
                                queryLoader.searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
                                style: TextStyle(decoration: queryLoader.searching ? TextDecoration.underline : null),
                              ),
                              onPressed: () async {
                                void onSubmit(BuildContext context) {
                                  Navigator.pop(context, true);
                                  pagination.offset = 0;
                                  reload();
                                }

                                DateTime? tempCreatedAfter = queryLoader.createdAfter;
                                DateTime? tempCreatedBefore = queryLoader.createdBefore;

                                final formKey = GlobalKey<FormState>();
                                final nameController = TextEditingController(text: queryLoader.name);
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          title: Text(AppLocale.ConfigureFilter.getString(context)),
                                          content: Form(
                                            key: formKey,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextFormField(
                                                  controller: nameController,
                                                  decoration: InputDecoration(
                                                    contentPadding: const EdgeInsets.all(8.0),
                                                    icon: const Icon(Icons.payment_outlined),
                                                    label: Text(AppLocale.Fee.getString(context)),
                                                  ),
                                                  onFieldSubmitted: (_) => onSubmit(context),
                                                  validator: (value) => nameValidator(context, required: false, value: value),
                                                ),
                                                const SizedBox.square(dimension: 10),
                                                Row(
                                                  children: [
                                                    Text(AppLocale.CreatedAfter.getString(context)),
                                                    const SizedBox.square(dimension: 5),
                                                    TextButton(
                                                      onPressed: () async {
                                                        DateTime? picked = await showDatePicker(
                                                          context: context,
                                                          initialDate: tempCreatedAfter,
                                                          firstDate: DateTime(2024),
                                                          lastDate: DateTime(2100),
                                                        );
                                                        setState(
                                                          () {
                                                            tempCreatedAfter = picked;
                                                          },
                                                        );
                                                      },
                                                      child: Text(tempCreatedAfter?.toLocal().toString() ?? "---"),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox.square(dimension: 10),
                                                Row(
                                                  children: [
                                                    Text(AppLocale.CreatedBefore.getString(context)),
                                                    const SizedBox.square(dimension: 5),
                                                    TextButton(
                                                      onPressed: () async {
                                                        DateTime? picked = await showDatePicker(
                                                          context: context,
                                                          initialDate: tempCreatedBefore,
                                                          firstDate: DateTime(2024),
                                                          lastDate: DateTime(2100),
                                                        );
                                                        setState(
                                                          () {
                                                            tempCreatedBefore = picked;
                                                          },
                                                        );
                                                      },
                                                      child: Text(tempCreatedBefore?.toLocal().toString() ?? "---"),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(AppLocale.Cancel.getString(context)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // Save the selected values
                                                queryLoader.name = nameController.text;
                                                queryLoader.createdAfter = tempCreatedAfter;
                                                queryLoader.createdBefore = tempCreatedBefore;

                                                Navigator.of(context).pop();
                                                reload();
                                              },
                                              child: Text(AppLocale.Search.getString(context)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                nameController.dispose();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
