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
  final selected = <Fee>{};

  static final _orderByMapping = [2, 1, 8, null, 3, 4, 5, 6, 7];

  int _sortIndex = 1;
  int? get sortIndex => _orderByMapping[_sortIndex] == null ? null : _sortIndex;
  set sortIndex(int? value) {
    if (value != null) {
      assert(_orderByMapping[_sortIndex] != null);
      _sortIndex = value;
    }
  }

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
        orderBy: _orderByMapping[_sortIndex] ?? -1,
        ascending: ascending,
      );

      final data = result.data;
      if (data != null) {
        selected.clear();
        fees.clear();
        fees.addAll(data);
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
  String name = "";
  DateTime? createdAfter;
  DateTime? createdBefore;

  bool get searching => name.isNotEmpty || createdAfter != null || createdBefore != null;

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

  final _horizontalScroll = ScrollController();

  @override
  CommonScaffold<FeeListPage> build(BuildContext context) {
    return CommonScaffold(
      widgetState: this,
      title: Text(AppLocale.FeeList.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  refresh();
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

                                reload();
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = [
                          DataColumn2(label: Text(AppLocale.FeeName.getString(context)), size: ColumnSize.L, onSort: onSort),
                          DataColumn2(label: Text(AppLocale.CreationTime.getString(context)), onSort: onSort),
                          DataColumn2(label: Text(AppLocale.Deadline.getString(context))),
                          DataColumn2(label: Text(AppLocale.Description.getString(context)), size: ColumnSize.L),
                          DataColumn2(label: Text(AppLocale.FeeLowerBound.getString(context)), onSort: onSort),
                          DataColumn2(label: Text(AppLocale.FeeUpperBound.getString(context)), onSort: onSort),
                          DataColumn2(label: Text(AppLocale.FeePerArea.getString(context)), onSort: onSort),
                          DataColumn2(label: Text(AppLocale.FeePerMotorbike.getString(context)), onSort: onSort),
                          DataColumn2(label: Text(AppLocale.FeePerCar.getString(context)), onSort: onSort),
                        ];
                        final scale = columns.map(
                          (c) {
                            switch (c.size) {
                              case ColumnSize.S:
                                return 0.67;
                              case ColumnSize.M:
                                return 1.0;
                              case ColumnSize.L:
                                return 1.2;
                            }
                          },
                        ).toList();
                        final baseWidth = constraints.maxWidth / scale.reduce((f, s) => f + s);

                        return DataTable2(
                          columns: columns,
                          fixedTopRows: 1,
                          horizontalScrollController: _horizontalScroll,
                          minWidth: 1200,
                          rows: queryLoader.fees.map(
                            (f) {
                              final data = [
                                f.name,
                                f.createdAt.toLocal().toString(),
                                f.deadline.format("dd/mm/yyyy"),
                                f.description,
                                f.lower.round().toString(),
                                f.upper.round().toString(),
                                f.perArea.round().toString(),
                                f.perMotorbike.round().toString(),
                                f.perCar.round().toString(),
                              ];

                              // Estimate row height from column size and text data
                              var maxHeight = 0.0;
                              for (var i = 0; i < data.length; i++) {
                                if (data[i].isEmpty) {
                                  continue;
                                }

                                final painter = TextPainter(
                                  text: TextSpan(text: data[i]),
                                  textDirection: TextDirection.ltr,
                                );
                                painter.layout(maxWidth: baseWidth * scale[i]);
                                maxHeight = max(maxHeight, painter.height);
                              }

                              return DataRow2(
                                cells: data
                                    .map(
                                      (s) => DataCell(
                                        Padding(
                                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                                          child: Text(s),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onSelectChanged: (selected) {
                                  if (selected != null) {
                                    if (selected) {
                                      queryLoader.selected.add(f);
                                    } else {
                                      queryLoader.selected.remove(f);
                                    }
                                    refresh();
                                  }
                                },
                                selected: queryLoader.selected.contains(f),
                                specificRowHeight: maxHeight > 0.0 ? 10 + maxHeight : null,
                              );
                            },
                          ).toList(growable: false),
                          showCheckboxColumn: true,
                          sortAscending: queryLoader.ascending,
                          sortColumnIndex: queryLoader.sortIndex,
                        );
                      },
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
