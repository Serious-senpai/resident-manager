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
        createdAfter: _state.createdAfter ?? epoch,
        createdBefore: _state.createdBefore ?? DateTime.now().add(const Duration(seconds: 3)), // SQL server timestamp may not synchronize with client
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
        createdBefore: _state.createdBefore ?? DateTime.now().add(const Duration(seconds: 3)), // SQL server timestamp may not synchronize with client
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
                  pushNamed: Navigator.pushReplacementNamed,
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
                                  final result = await Fee.create(
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

                                  if (result.code == 0) {
                                    _notification = const SizedBox.shrink();
                                  } else {
                                    _notification = Builder(
                                      builder: (context) => Text(
                                        AppLocale.errorMessage(result.code).getString(context),
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }

                                  reload();
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

                        final mediaQuery = MediaQuery.of(context);
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(AppLocale.AddANewFee.getString(context)),
                            content: SizedBox(
                              height: 0.8 * mediaQuery.size.height,
                              width: 0.5 * mediaQuery.size.width,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: StatefulBuilder(
                                  builder: (context, setState) => Form(
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
                                          validator: (value) => feeUpperValidator(
                                            context,
                                            lower: double.tryParse(lowerController.text),
                                            required: true,
                                            value: value,
                                          ),
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
                                                  firstDate: DateTime.now(),
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
                                        Expanded(
                                          child: TextFormField(
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
                                            maxLength: 1500,
                                            maxLines: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

            const fontSize = 14.0, height = 1.2;
            final headerText = [
              AppLocale.FeeName.getString(context),
              AppLocale.CreationTime.getString(context),
              AppLocale.Deadline.getString(context),
              AppLocale.Description.getString(context),
              AppLocale.FeeLowerBound.getString(context),
              AppLocale.FeeUpperBound.getString(context),
              AppLocale.FeePerArea.getString(context),
              AppLocale.FeePerMotorbike.getString(context),
              AppLocale.FeePerCar.getString(context),
            ];

            final columnSort = [true, true, false, false, true, true, true, true, true];
            final columnNumeric = [false, false, false, false, true, true, true, true, true];
            final columnSize = [
              ColumnSize.M,
              ColumnSize.M,
              ColumnSize.M,
              ColumnSize.L,
              ColumnSize.M,
              ColumnSize.M,
              ColumnSize.M,
              ColumnSize.M,
              ColumnSize.M,
            ];
            final columns = List<DataColumn2>.generate(
              headerText.length,
              (index) => DataColumn2(
                label: Text(
                  headerText[index],
                  softWrap: true,
                  style: const TextStyle(fontSize: fontSize, height: height),
                ),
                onSort: columnSort[index] ? onSort : null,
                numeric: columnNumeric[index],
                size: columnSize[index],
              ),
            );

            return SliverLayoutBuilder(
              builder: (context, constraints) => SliverToBoxAdapter(
                child: SizedBox(
                  height: constraints.remainingPaintExtent,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: DataTable2(
                      columns: columns,
                      columnSpacing: 5,
                      dataRowHeight: 4 * height * fontSize,
                      fixedTopRows: 1,
                      headingRowHeight: 4 * height * fontSize,
                      horizontalScrollController: _horizontalScroll,
                      minWidth: 1200,
                      rows: queryLoader.fees.map(
                        (f) {
                          final text = [
                            f.name,
                            formatDateTime(f.createdAt.toLocal()),
                            f.deadline.format("dd/mm/yyyy"),
                            f.description,
                            formatVND(f.lower),
                            formatVND(f.upper),
                            formatVND(f.perArea),
                            formatVND(f.perMotorbike),
                            formatVND(f.perCar),
                          ];

                          return DataRow2(
                            cells: List<DataCell>.generate(
                              text.length,
                              (index) => DataCell(
                                Padding(
                                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                                  child: Text(
                                    text[index],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(fontSize: fontSize, height: height),
                                  ),
                                ),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(headerText[index]),
                                    content: Builder(
                                      builder: (context) {
                                        final mediaQuery = MediaQuery.of(context);
                                        return ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: 0.75 * mediaQuery.size.height),
                                          child: SingleChildScrollView(child: Text(text[index])),
                                        );
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(AppLocale.OK.getString(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).toList(growable: false),
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
                          );
                        },
                      ).toList(growable: false),
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
