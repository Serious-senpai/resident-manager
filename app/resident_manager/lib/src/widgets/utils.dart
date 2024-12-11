import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../routes.dart";
import "../state.dart";
import "../translations.dart";
import "../utils.dart";
import "../models/reg_request.dart";
import "../models/residents.dart";
import "../models/rooms.dart";

class HoverContainer extends StatefulWidget {
  final Color onHover;
  final Widget child;

  const HoverContainer({super.key, required this.onHover, required this.child});

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered ? widget.onHover : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class SliverCircularProgressFullScreen extends StatelessWidget {
  const SliverCircularProgressFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
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
      ),
    );
  }
}

class SliverErrorFullScreen extends StatelessWidget {
  final int? _errorCode;
  final void Function()? _callback;

  const SliverErrorFullScreen({
    super.key,
    required int? errorCode,
    required void Function()? callback,
  })  : _errorCode = errorCode,
        _callback = callback;

  @override
  Widget build(BuildContext context) {
    final code = _errorCode;
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
            const SizedBox.square(dimension: 5),
            TextButton.icon(
              icon: const Icon(Icons.refresh_outlined),
              label: Text(AppLocale.Retry.getString(context)),
              onPressed: _callback,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_outlined),
            onPressed: () => Navigator.pop(context, true),
            label: Text(AppLocale.Yes.getString(context)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.close_outlined),
            onPressed: () => Navigator.pop(context, false),
            label: Text(AppLocale.No.getString(context)),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<int> _countRegistrationRequests(ApplicationState state) async {
  final result = await RegisterRequest.count(state: state);
  return result.data ?? 0;
}

Future<int> _countResidents(ApplicationState state) async {
  final result = await Resident.count(state: state);
  return result.data ?? 0;
}

Future<int> _countRooms(ApplicationState state) async {
  final result = await Room.count(state: state);
  return result.data ?? 0;
}

abstract class _AccountCountWidget extends StateAwareWidget {
  final TextStyle? numberStyle;
  final TextStyle? labelStyle;

  const _AccountCountWidget({
    super.key,
    required super.state,
    this.numberStyle,
    this.labelStyle,
  });

  Future<int> run(BuildContext context);
  String getLabel(BuildContext context, int quantity);

  @override
  State<_AccountCountWidget> createState() => _AccountCountWidgetState();
}

class _AccountCountWidgetState extends State<_AccountCountWidget> {
  Future<int>? _future;

  @override
  Widget build(BuildContext context) {
    _future ??= widget.run(context);
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(
            heightFactor: 1,
            widthFactor: 1,
            child: CircularProgressIndicator(),
          );
        }
        return Column(
          children: [
            Text(data.toString(), style: widget.numberStyle),
            Text(widget.getLabel(context, data), style: widget.labelStyle),
          ],
        );
      },
    );
  }
}

class RegistrationRequestCounter extends _AccountCountWidget {
  const RegistrationRequestCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  });

  @override
  Future<int> run(BuildContext context) => _countRegistrationRequests(state);

  @override
  String getLabel(BuildContext context, int quantity) {
    final base = quantity == 1 ? AppLocale.RegistrationRequest : AppLocale.RegistrationRequests;
    return base.getString(context);
  }
}

class ResidentCounter extends _AccountCountWidget {
  const ResidentCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  });

  @override
  Future<int> run(BuildContext context) => _countResidents(state);

  @override
  String getLabel(BuildContext context, int quantity) {
    final base = quantity == 1 ? AppLocale.Resident : AppLocale.Residents;
    return base.getString(context);
  }
}

class RoomCounter extends _AccountCountWidget {
  const RoomCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  });

  @override
  Future<int> run(BuildContext context) => _countRooms(state);

  @override
  String getLabel(BuildContext context, int quantity) {
    final base = quantity == 1 ? AppLocale.Room : AppLocale.Rooms;
    return base.getString(context);
  }
}

/// https://github.com/imaNNeo/fl_chart/blob/main/example/lib/presentation/widgets/indicator.dart
class _ChartIndicator extends StatelessWidget {
  final Color color;
  final bool square;
  final Text text;

  const _ChartIndicator({
    required this.color,
    required this.square,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: square ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        text,
      ],
    );
  }
}

class AccountsPieChart extends StateAwareWidget {
  final double? height;
  final double? width;

  const AccountsPieChart({
    super.key,
    required super.state,
    this.height,
    this.width,
  });

  @override
  State<AccountsPieChart> createState() => _AccountsPieChartState();
}

class _AccountsPieChartState extends AbstractCommonState<AccountsPieChart> {
  Future<int>? _requestsFuture;
  Future<int> get requests => _requestsFuture ??= _countRegistrationRequests(state);

  Future<int>? _residentsFuture;
  Future<int> get residents => _residentsFuture ??= _countResidents(state);

  void reload() {
    _requestsFuture = null;
    _residentsFuture = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder(
              future: requests,
              builder: (context, snapshot1) => FutureBuilder(
                future: residents,
                builder: (context, snapshot2) {
                  final requests = snapshot1.data, residents = snapshot2.data;
                  return Center(
                    child: (requests == null || residents == null)
                        ? const CircularProgressIndicator()
                        : PieChart(
                            PieChartData(
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  color: Colors.red,
                                  showTitle: false,
                                  value: requests.toDouble(),
                                ),
                                PieChartSectionData(
                                  color: Colors.blue,
                                  showTitle: false,
                                  value: residents.toDouble(),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChartIndicator(
                color: Colors.red,
                square: true,
                text: Text(AppLocale.RegistrationRequests.getString(context)),
              ),
              const SizedBox.square(dimension: 5),
              _ChartIndicator(
                color: Colors.blue,
                square: true,
                text: Text(AppLocale.Residents.getString(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewAccountGraph extends StateAwareWidget {
  final double? height;
  final double? width;

  const NewAccountGraph({
    super.key,
    required super.state,
    this.height,
    this.width,
  });

  @override
  State<NewAccountGraph> createState() => _NewAccountGraphState();
}

class _NewAccountGraphState extends AbstractCommonState<NewAccountGraph> {
  static const int MONTHS = 6;
  Future<List<int>>? _future;
  Future<List<int>> get future => _future ??= _countResidents();

  DateTime _subtractMonth(DateTime date, int months) {
    if (months > 0) {
      if (months < date.month) {
        return DateTime(date.year, date.month - months);
      } else {
        return DateTime(date.year - 1, date.month + 12 - months);
      }
    } else {
      return date;
    }
  }

  Future<List<int>> _countResidents() async {
    final now = DateTime.now();
    final results = await Future.wait(
      List<Future<int>>.generate(
        MONTHS,
        (index) async {
          final createdAfter = _subtractMonth(now, index);
          final createdBefore = _subtractMonth(now, index - 1);

          final result = await Resident.count(
            state: state,
            createdAfter: createdAfter,
            createdBefore: createdBefore,
          );

          return result.data ?? 0;
        },
      ),
    );

    return List<int>.from(results.reversed);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              barGroups: List.generate(
                data.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data[index].toDouble(),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              barTouchData: BarTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, metadata) {
                      final date = _subtractMonth(DateTime.now(), MONTHS - (value.toInt() + 1));
                      return Text(
                        mediaQuery.size.width < ScreenWidth.MEDIUM ? date.month.toString() : "${date.month}/${date.year}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  axisNameWidget: Text(
                    AppLocale.NumberOfNewResidents.getString(context),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  axisNameSize: 32,
                  sideTitles: const SideTitles(showTitles: false),
                ),
                show: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminMonitorWidget extends StatelessWidget {
  final ApplicationState state;
  final void Function(BuildContext context, String routeName) pushNamed;

  const AdminMonitorWidget({super.key, required this.state, required this.pushNamed});

  @override
  Widget build(BuildContext context) {
    final requestCounter = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: InkWell(
          onTap: () => pushNamed(context, ApplicationRoute.adminRegisterQueue),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: RegistrationRequestCounter(
              state: state,
              numberStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              labelStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
    final residentCounter = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: InkWell(
          onTap: () => pushNamed(context, ApplicationRoute.adminResidentsPage),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: ResidentCounter(
              state: state,
              numberStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              labelStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
    final roomCounter = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: InkWell(
          onTap: () => pushNamed(context, ApplicationRoute.adminRoomsPage),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: RoomCounter(
              state: state,
              numberStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              labelStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    var graphPadding = const EdgeInsets.fromLTRB(40, 10, 40, 10);
    if (mediaQuery.size.width < ScreenWidth.LARGE) {
      graphPadding /= 2;
    }

    const chartBoxHeight = 200.0;
    final newAccountGraph = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: graphPadding,
          child: NewAccountGraph(state: state, height: chartBoxHeight),
        ),
      ),
    );
    final pieChart = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: graphPadding,
          child: AccountsPieChart(state: state, height: chartBoxHeight),
        ),
      ),
    );

    return mediaQuery.size.width > ScreenWidth.LARGE
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: requestCounter),
                  Expanded(child: residentCounter),
                  Expanded(child: roomCounter),
                ],
              ),
              Row(
                children: [
                  Expanded(flex: 2, child: newAccountGraph),
                  Expanded(flex: 1, child: pieChart),
                ],
              ),
            ],
          )
        : Column(
            children: List<Widget>.from(
              [
                requestCounter,
                residentCounter,
                roomCounter,
              ].map(
                (w) => Row(
                  children: [Expanded(child: w)],
                ),
              ),
            ),
          );
  }
}

class AdminAccountSearchButton extends StatelessWidget {
  final String? Function() getName;
  final String? Function() getRoom;
  final String? Function() getUsername;
  final bool Function() getSearching;
  final void Function(String?) setName;
  final void Function(String?) setRoom;
  final void Function(String?) setUsername;
  final void Function(int) setPageOffset;
  final void Function() reload;

  const AdminAccountSearchButton({
    super.key,
    required this.getName,
    required this.getRoom,
    required this.getUsername,
    required this.getSearching,
    required this.setName,
    required this.setRoom,
    required this.setUsername,
    required this.setPageOffset,
    required this.reload,
  });

  @override
  Widget build(BuildContext context) {
    final name = getName();
    final room = getRoom();
    final username = getUsername();
    final searching = getSearching();

    return TextButton.icon(
      icon: Icon(searching ? Icons.search_outlined : Icons.search_off_outlined),
      label: Text(
        searching ? AppLocale.Searching.getString(context) : AppLocale.Search.getString(context),
        style: TextStyle(decoration: searching ? TextDecoration.underline : null),
      ),
      onPressed: () async {
        final nameController = TextEditingController(text: name);
        final roomController = TextEditingController(text: room);
        final usernameController = TextEditingController(text: username);
        final formKey = GlobalKey<FormState>();

        void onSubmit(BuildContext context) {
          if (formKey.currentState?.validate() ?? false) {
            setName(nameController.text);
            setRoom(roomController.text);
            setUsername(usernameController.text);
            setPageOffset(0);

            Navigator.pop(context, true);
            reload();
          }
        }

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            contentPadding: const EdgeInsets.all(10),
            title: Text(AppLocale.Search.getString(context)),
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
                      icon: const Icon(Icons.badge_outlined),
                      label: Text(AppLocale.Fullname.getString(context)),
                    ),
                    onFieldSubmitted: (_) => onSubmit(context),
                    validator: (value) => nameValidator(context, required: false, value: value),
                  ),
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
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      icon: const Icon(Icons.person_outlined),
                      label: Text(AppLocale.Username.getString(context)),
                    ),
                    onFieldSubmitted: (_) => onSubmit(context),
                    validator: (value) => usernameValidator(context, required: false, value: value),
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
                  roomController.clear();
                  usernameController.clear();

                  onSubmit(context);
                },
              ),
            ],
          ),
        );

        // nameController.dispose();
        // roomController.dispose();
        // usernameController.dispose();
      },
    );
  }
}
