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
        name: _state.name,
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
        createdAfter: _state.createdAfter ?? epoch,
        createdBefore: _state.createdBefore ?? DateTime.now(),
        name: _state.name,
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
  String? name;
  DateTime? createdAfter;
  DateTime? createdBefore;

  bool get searching => name != null || createdAfter != null || createdBefore != null;

  _Pagination? _pagination;
  _Pagination get pagination => _pagination ??= _Pagination(this);

  _QueryLoader? _queryLoader;
  _QueryLoader get queryLoader => _queryLoader ??= _QueryLoader(this);

  final _actionLock = Lock();
  Widget _notification = const SizedBox.shrink();

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
                  headerCeil(AppLocale.FeeName.getString(context), 2),
                  headerCeil(AppLocale.CreationTime.getString(context), 1),
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
                        child: Text(fee.createdAt.toLocal().toString()),
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
                        AdminMonitorWidget(
                          state: state,
                          pushNamed: pushNamedAndRefresh,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.add_outlined),
                              label: Text(AppLocale.AddANewFee.getString(context)),
                              onPressed: () async {
                                final nameController = TextEditingController();
                                final lowerController = TextEditingController();
                                final upperController = TextEditingController();
                                final perAreaController = TextEditingController();
                                final perMotorbikeController = TextEditingController();
                                final perCarController = TextEditingController();
                                var deadline = Date.now();
                                final descriptionController = TextEditingController();
                                final formKey = GlobalKey<FormState>();

                                Future<void> onSubmit(BuildContext context) async {
                                  return; // TODO: Fix the dialog below
                                  await _actionLock.run(
                                    () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        Navigator.pop(context);

                                        _notification = Builder(
                                          builder: (context) => Text(
                                            AppLocale.Loading.getString(context),
                                            style: const TextStyle(color: Colors.blue),
                                          ),
                                        );
                                        refresh();

                                        try {
                                          await Fee.create(
                                            state: state,
                                            name: nameController.text,
                                            lower: double.parse(lowerController.text),
                                            upper: double.parse(upperController.text),
                                            perArea: double.parse(perAreaController.text),
                                            perMotorbike: double.parse(perMotorbikeController.text),
                                            perCar: double.parse(perCarController.text),
                                            deadline: deadline,
                                            description: descriptionController.text,
                                            flags: 0,
                                          );

                                          _notification = const SizedBox.shrink();
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
                                        }
                                      }
                                    },
                                  );
                                }

                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    contentPadding: const EdgeInsets.all(10),
                                    title: Text(AppLocale.AddANewFee.getString(context)),
                                    content: Form(
                                      key: formKey,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeeName.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => nameValidator(context, required: true, value: value),
                                          ),
                                          TextFormField(
                                            controller: lowerController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeeLowerBound.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => feeLowerValidator(context, required: true, value: value),
                                          ),
                                          TextFormField(
                                            controller: upperController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeeUpperBound.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => feeUpperValidator(context, required: true, value: value),
                                          ),
                                          TextFormField(
                                            controller: perAreaController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeePerArea.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => feePerAreaValidator(context, required: true, value: value),
                                          ),
                                          TextFormField(
                                            controller: perMotorbikeController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeePerMotorbike.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => feePerMotorbikeValidator(context, required: true, value: value),
                                          ),
                                          TextFormField(
                                            controller: perCarController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.FeePerCar.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            validator: (value) => feePerCarValidator(context, required: true, value: value),
                                          ),
                                          const SizedBox.square(dimension: 5),
                                          Row(
                                            children: [
                                              Text(AppLocale.Deadline.getString(context)),
                                              const SizedBox.square(dimension: 5),
                                              TextButton(
                                                onPressed: () async {
                                                  DateTime? picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: deadline.toDateTime(),
                                                    firstDate: DateTime(2024),
                                                    lastDate: DateTime(2100),
                                                  );
                                                  setState(
                                                    () {
                                                      if (picked != null) deadline = Date.fromDateTime(picked);
                                                    },
                                                  );
                                                },
                                                child: Text(deadline.format("dd/mm/yyyy")),
                                              ),
                                            ],
                                          ),
                                          const SizedBox.square(dimension: 5),
                                          TextFormField(
                                            controller: descriptionController,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.all(8.0),
                                              enabledBorder: const OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.black, width: 1),
                                              ),
                                              floatingLabelBehavior: FloatingLabelBehavior.always,
                                              label: FieldLabel(
                                                AppLocale.Description.getString(context),
                                                style: const TextStyle(color: Colors.black),
                                                required: true,
                                              ),
                                            ),
                                            onFieldSubmitted: (_) => onSubmit(context),
                                            maxLength: 4000,
                                            maxLines: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.done_outlined),
                                        label: Text(AppLocale.Confirm.getString(context)),
                                        onPressed: () => onSubmit(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                                final nameController = TextEditingController(text: name);
                                var tempCreatedAfter = createdAfter;
                                var tempCreatedBefore = createdBefore;
                                final formKey = GlobalKey<FormState>();

                                void onSubmit(BuildContext context) {
                                  if (formKey.currentState?.validate() ?? false) {
                                    name = nameController.text;
                                    createdAfter = tempCreatedAfter;
                                    createdBefore = tempCreatedBefore;
                                    pagination.offset = 0;

                                    Navigator.pop(context, true);
                                    reload();
                                  }
                                }

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
                                                    label: Text(AppLocale.FeeName.getString(context)),
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
                                                        setState(() => tempCreatedAfter = picked);
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
                                                        setState(() => tempCreatedBefore = picked);
                                                      },
                                                      child: Text(tempCreatedBefore?.toLocal().toString() ?? "---"),
                                                    ),
                                                  ],
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
                                                nameController.clear();
                                                tempCreatedAfter = null;
                                                tempCreatedBefore = null;

                                                onSubmit(context);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );

                                // nameController.dispose();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _notification),
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
