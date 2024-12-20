import "dart:async";
import "dart:io";
import "dart:math";

import "package:data_table_2/data_table_2.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../utils.dart";
import "../../config.dart";
import "../../translations.dart";
import "../../utils.dart";
import "../../models/payment_status.dart";

class PaymentListPage extends StateAwareWidget {
  const PaymentListPage({super.key, required super.state});

  @override
  AbstractCommonState<PaymentListPage> createState() => _PaymentListPageState();
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int count = 0;
  int get offsetLimit => max(offset, (count + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1);

  // final _PaymentListPageState _state;

  // _Pagination(this._state);

  @override
  Future<int?> run() async => 0;
}

class _QueryLoader extends FutureHolder<int?> {
  final statuses = <PaymentStatus>[];

  final _PaymentListPageState _state;

  _QueryLoader(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await PaymentStatus.adminQuery(
        state: _state.state,
        room: int.tryParse(_state.room),
        paid: _state.paid,
        offset: DB_PAGINATION_QUERY * _state.pagination.offset,
        createdAfter: _state.createdAfter ?? epoch,
        createdBefore: _state.createdBefore ?? DateTime.now().add(const Duration(seconds: 3)), // SQL server timestamp may not synchronize with client
      );

      final data = result.data;
      if (data != null) {
        statuses.clear();
        statuses.addAll(data);
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

class _PaymentListPageState extends AbstractCommonState<PaymentListPage> with CommonScaffoldStateMixin<PaymentListPage> {
  String room = "";
  bool? paid;
  DateTime? createdAfter;
  DateTime? createdBefore;

  bool get searching => room.isNotEmpty || paid != null || createdAfter != null || createdBefore != null;

  _Pagination? _pagination;
  _Pagination get pagination => _pagination ??= _Pagination();

  _QueryLoader? _queryLoader;
  _QueryLoader get queryLoader => _queryLoader ??= _QueryLoader(this);

  void reload() {
    pagination.reload();
    queryLoader.reload();
    refresh();
  }

  final _horizontalScroll = ScrollController();

  @override
  CommonScaffold<PaymentListPage> build(BuildContext context) {
    return CommonScaffold(
      widgetState: this,
      title: Text(AppLocale.PaymentList.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        final offset = pagination.offset;
                        return Text("${offset + 1}");
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_outlined),
                      onPressed: () {
                        // if (pagination.offset < pagination.offsetLimit) {
                        pagination.offset++;
                        reload();
                        // }
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
                        final roomController = TextEditingController(text: room);
                        bool? tempPaid = paid;
                        DateTime? tempCreatedAfter = createdAfter;
                        DateTime? tempCreatedBefore = createdBefore;

                        final formKey = GlobalKey<FormState>();

                        void onSubmit(BuildContext context) {
                          if (formKey.currentState?.validate() ?? false) {
                            room = roomController.text;
                            paid = tempPaid;
                            createdAfter = tempCreatedAfter;
                            createdBefore = tempCreatedBefore;
                            pagination.offset = 0;

                            Navigator.pop(context, true);
                            reload();
                          }
                        }

                        await showDialog(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setState) => AlertDialog(
                              title: Text(AppLocale.ConfigureFilter.getString(context)),
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
                                    const SizedBox.square(dimension: 10),
                                    Row(
                                      children: [
                                        Text(AppLocale.PaymentStatus.getString(context)),
                                        const SizedBox.square(dimension: 5),
                                        DropdownButton<bool?>(
                                          value: tempPaid,
                                          hint: Text(AppLocale.PaymentStatus.getString(context)),
                                          items: [
                                            DropdownMenuItem(value: null, child: Text(AppLocale.All.getString(context))),
                                            DropdownMenuItem(value: true, child: Text(AppLocale.AlreadyPaid.getString(context))),
                                            DropdownMenuItem(value: false, child: Text(AppLocale.NotPaid.getString(context))),
                                          ],
                                          onChanged: (value) {
                                            setState(() => tempPaid = value);
                                          },
                                        ),
                                      ],
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
                                TextButton(
                                  onPressed: () {
                                    tempPaid = null;
                                    tempCreatedAfter = null;
                                    tempCreatedBefore = null;

                                    onSubmit(context);
                                  },
                                  child: Text(AppLocale.ClearAll.getString(context)),
                                ),
                                TextButton(
                                  onPressed: () => onSubmit(context),
                                  child: Text(AppLocale.Search.getString(context)),
                                ),
                              ],
                            ),
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
        // SliverToBoxAdapter(child: Center(child: _notification)),
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

            const fontSize = 14.0, height = 1.2;
            final headerText = [
              AppLocale.FeeName.getString(context),
              AppLocale.Description.getString(context),
              AppLocale.Room.getString(context),
              AppLocale.CreationTime.getString(context),
              AppLocale.PaidTimestamp.getString(context),
              AppLocale.FeeLowerBound.getString(context),
              AppLocale.FeeUpperBound.getString(context),
              AppLocale.AmountPaid.getString(context),
            ];

            final columnNumeric = [false, false, false, false, false, true, true, true];
            final columnSize = [
              ColumnSize.M,
              ColumnSize.L,
              ColumnSize.S,
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
                      rows: queryLoader.statuses.map(
                        (p) {
                          final text = [
                            p.fee.name,
                            p.fee.description,
                            p.room.toString(),
                            formatDateTime(p.fee.createdAt.toLocal()),
                            p.payment != null ? formatDateTime(p.payment!.createdAt.toLocal()) : "---",
                            formatVND(p.lowerBound),
                            formatVND(p.upperBound),
                            p.payment == null ? "---" : formatVND(p.payment!.amount),
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
                          );
                        },
                      ).toList(growable: false),
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
