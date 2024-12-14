import "dart:async";
import "dart:io";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:url_launcher/url_launcher.dart";

import "common.dart";
import "state.dart";
import "utils.dart";
import "../config.dart";
import "../state.dart";
import "../translations.dart";
import "../utils.dart";
import "../models/payment_status.dart";

class PaymentPage extends StateAwareWidget {
  const PaymentPage({super.key, required super.state});

  @override
  AbstractCommonState<PaymentPage> createState() => _PaymentPageState();
}

class _Pagination extends FutureHolder<int?> {
  int offset = 0;
  int count = 0;
  int get offsetLimit => max(offset, (count + DB_PAGINATION_QUERY - 1) ~/ DB_PAGINATION_QUERY - 1);

  final _PaymentPageState _state;

  _Pagination(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await PaymentStatus.count(
        state: _state.state,
        paid: _state.paid,
        createdAfter: _state.createdAfter ?? epoch,
        createdBefore: _state.createdBefore ?? DateTime.now().toUtc(),
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
  final statuses = <PaymentStatus>[];

  final _PaymentPageState _state;

  _QueryLoader(this._state);

  @override
  Future<int?> run() async {
    try {
      final result = await PaymentStatus.query(
        state: _state.state,
        offset: DB_PAGINATION_QUERY * _state.pagination.offset,
        paid: _state.paid,
        createdAfter: _state.createdAfter ?? epoch,
        createdBefore: _state.createdBefore ?? DateTime.now().toUtc(),
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

class _PayButton extends StatelessWidget {
  final ApplicationState state;
  final PaymentStatus status;

  const _PayButton({required this.state, required this.status});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.payment_outlined),
      onPressed: status.payment != null
          ? null
          : () async {
              var amount = status.lowerBound;

              if (status.upperBound != amount) {
                final controller = TextEditingController();
                final selected = await showDialog<double>(
                  context: context,
                  builder: (context) {
                    final formKey = GlobalKey<FormState>();
                    return SimpleDialog(
                      title: Text(AppLocale.Payment.getString(context)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Form(
                            key: formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              children: [
                                TextFormField(
                                  autofocus: true,
                                  controller: controller,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(8.0),
                                    label: FieldLabel(
                                      AppLocale.EnterAmount.getString(context),
                                      style: const TextStyle(color: Colors.black),
                                      required: true,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty && value.length < 9) {
                                      final numValue = double.tryParse(value);
                                      if (numValue != null && numValue >= status.lowerBound && numValue <= status.upperBound) {
                                        return null;
                                      }
                                    }

                                    final message = AppLocale.AmountMustBeFromTo.getString(context);
                                    return message
                                        .replaceFirst(
                                          "{min}",
                                          status.lowerBound.round().toString(),
                                        )
                                        .replaceFirst(
                                          "{max}",
                                          status.upperBound.round().toString(),
                                        );
                                  },
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
                                        Navigator.pop(context, double.parse(controller.text));
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                // controller.dispose();
                if (selected == null) {
                  return;
                }

                amount = selected;
              }

              await launchUrl(
                ApplicationState.baseUrl.replace(
                  path: "/api/v1/residents/pay",
                  queryParameters: {
                    "room": state.resident?.room.toString(),
                    "fee_id": status.fee.id.toString(),
                    "amount": amount.toString(),
                  },
                ),
                mode: LaunchMode.inAppWebView,
              );
            },
    );
  }
}

class _PaymentPageState extends AbstractCommonState<PaymentPage> with CommonScaffoldStateMixin<PaymentPage> {
  bool? paid;
  DateTime? createdAfter;
  DateTime? createdBefore;

  bool get searching => paid != null || createdAfter != null || createdBefore != null;

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
  CommonScaffold<PaymentPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Payment.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: FutureBuilder(
        future: queryLoader.future,
        initialData: queryLoader.lastData,
        builder: (context, snapshot) {
          if (queryLoader.isLoading) {
            return const SliverCircularProgressFullScreen();
          }

          final code = queryLoader.lastData;
          if (code == 0) {
            return SliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(5),
                  sliver: SliverToBoxAdapter(
                    child: Row(
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
                            return Text("${pagination.offset + 1}/${pagination.offsetLimit + 1}");
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_outlined),
                          onPressed: () {
                            pagination.offset++;
                            reload();
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
                            bool? tempPaid = paid;
                            DateTime? tempCreatedAfter = createdAfter;
                            DateTime? tempCreatedBefore = createdBefore;

                            void onSubmit(BuildContext context) {
                              paid = tempPaid;
                              createdAfter = tempCreatedAfter;
                              createdBefore = tempCreatedBefore;
                              pagination.offset = 0;

                              Navigator.pop(context, true);
                              reload();
                            }

                            await showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: Text(AppLocale.ConfigureFilter.getString(context)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                    );
                                  },
                                );
                              },
                            );
                          },
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
                        child: Table(
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(border: BorderDirectional(bottom: BorderSide(width: 1))),
                              children: [
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.Fee.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.Description.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.Minimum.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.Maximum.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.CreationTime.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.AmountPaid.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      AppLocale.Option.getString(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            for (final status in queryLoader.statuses)
                              TableRow(
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.fee.name),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.fee.description),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.lowerBound.round().toString()),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.upperBound.round().toString()),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.fee.createdAt.toString()),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.payment?.amount.round().toString() ?? "---"),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Row(
                                        children: [
                                          _PayButton(state: state, status: status),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (code == 606) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  AppLocale.Error606.getString(context),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return SliverErrorFullScreen(errorCode: code, callback: reload);
        },
      ),
    );
  }
}
