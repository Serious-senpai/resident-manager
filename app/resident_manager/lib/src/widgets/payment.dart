import "dart:async";
import "dart:io";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "utils.dart";
import "../config.dart";
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

  @override
  Future<int?> run() async {
    return offset;
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
        createdFrom: epoch,
        createdTo: DateTime.now().toUtc(),
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

class _PaymentPageState extends AbstractCommonState<PaymentPage> with CommonStateMixin<PaymentPage> {
  _Pagination? _pagination;
  _Pagination get pagination => _pagination ??= _Pagination();

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
                            final offset = pagination.offset;
                            return Text("${offset + 1}");
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
                                      child: Text(status.lowerBound.floor().toString()),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(status.upperBound.floor().toString()),
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
                                      child: Text(status.payment?.amount.toString() ?? "---"),
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
          }

          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
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
            ),
          );
        },
      ),
    );
  }
}
