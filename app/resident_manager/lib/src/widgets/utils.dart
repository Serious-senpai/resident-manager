import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "../routes.dart";
import "../state.dart";
import "../translations.dart";
import "../utils.dart";
import "../models/reg_request.dart";
import "../models/residents.dart";
import "../models/rooms.dart";

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

class ErrorIndicator extends StatelessWidget {
  final int? _errorCode;
  final void Function()? _callback;

  const ErrorIndicator({
    super.key,
    required int? errorCode,
    required void Function()? callback,
  })  : _errorCode = errorCode,
        _callback = callback;

  @override
  Widget build(BuildContext context) {
    final code = _errorCode;
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
          const SizedBox.square(dimension: 5),
          TextButton.icon(
            icon: const Icon(Icons.refresh_outlined),
            label: Text(AppLocale.Retry.getString(context)),
            onPressed: _callback,
          ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String _label;
  final TextStyle? _style;
  final bool _required;

  const FieldLabel(String label, {super.key, TextStyle? style, bool required = false})
      : _label = label,
        _style = style,
        _required = required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _label,
        style: _style,
        children: _required ? const [TextSpan(text: " *", style: TextStyle(color: Colors.red))] : [],
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

abstract class _CounterFuture extends FutureHolder<int> {
  final ApplicationState state;

  _CounterFuture(this.state);
}

class _RegistrationRequestCount extends _CounterFuture {
  static _RegistrationRequestCount? instance;

  _RegistrationRequestCount(super.state);

  @override
  Future<int> run() async {
    final result = await RegisterRequest.count(state: state);
    return result.data ?? 0;
  }
}

class _ResidentCount extends _CounterFuture {
  static _ResidentCount? instance;

  _ResidentCount(super.state);

  @override
  Future<int> run() async {
    final result = await Resident.count(state: state);
    return result.data ?? 0;
  }
}

class _RoomCount extends _CounterFuture {
  static _RoomCount? instance;

  _RoomCount(super.state);

  @override
  Future<int> run() async {
    final result = await Room.count(state: state);
    return result.data ?? 0;
  }
}

abstract class _AccountCountWidget extends StateAwareWidget {
  final TextStyle? numberStyle;
  final TextStyle? labelStyle;
  final _CounterFuture holder;

  const _AccountCountWidget({
    super.key,
    required super.state,
    this.numberStyle,
    this.labelStyle,
    required this.holder,
  });

  String getLabel(BuildContext context, int quantity);

  @override
  State<_AccountCountWidget> createState() => _AccountCountWidgetState();
}

class _AccountCountWidgetState extends State<_AccountCountWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.holder.future,
      builder: (context, snapshot) {
        final data = widget.holder.lastData;
        if (data == null) {
          return const Center(
            heightFactor: 1,
            widthFactor: 1,
            child: CircularProgressIndicator(),
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.toString(), style: widget.numberStyle, textAlign: TextAlign.center),
            Text(widget.getLabel(context, data), style: widget.labelStyle, textAlign: TextAlign.center),
          ],
        );
      },
    );
  }
}

class RegistrationRequestCounter extends _AccountCountWidget {
  RegistrationRequestCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  }) : super(holder: _RegistrationRequestCount.instance ??= _RegistrationRequestCount(state));

  @override
  String getLabel(BuildContext context, int quantity) {
    final base = quantity == 1 ? AppLocale.RegistrationRequest : AppLocale.RegistrationRequests;
    return base.getString(context);
  }
}

class ResidentCounter extends _AccountCountWidget {
  ResidentCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  }) : super(holder: _ResidentCount.instance ??= _ResidentCount(state));

  @override
  String getLabel(BuildContext context, int quantity) {
    final base = quantity == 1 ? AppLocale.Resident : AppLocale.Residents;
    return base.getString(context);
  }
}

class RoomCounter extends _AccountCountWidget {
  RoomCounter({
    super.key,
    required super.state,
    super.numberStyle,
    super.labelStyle,
  }) : super(holder: _RoomCount.instance ??= _RoomCount(state));

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
  final Widget label;

  const _ChartIndicator({
    required this.color,
    required this.square,
    required this.label,
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
        label,
      ],
    );
  }
}

class AccountsPieChart extends StateAwareWidget {
  final double? height;
  final double? width;
  final TextStyle? labelStyle;

  const AccountsPieChart({
    super.key,
    required super.state,
    this.height,
    this.width,
    this.labelStyle,
  });

  @override
  State<AccountsPieChart> createState() => _AccountsPieChartState();
}

class _AccountsPieChartState extends AbstractCommonState<AccountsPieChart> {
  @override
  Widget build(BuildContext context) {
    final requestsHolder = _RegistrationRequestCount.instance ??= _RegistrationRequestCount(state);
    final residentsHolder = _ResidentCount.instance ??= _ResidentCount(state);
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder(
              future: requestsHolder.future,
              builder: (context, _) => FutureBuilder(
                future: residentsHolder.future,
                builder: (context, _) {
                  final requests = requestsHolder.lastData, residents = residentsHolder.lastData;
                  return Center(
                    child: (requests == null || residents == null)
                        ? const CircularProgressIndicator()
                        : PieChart(
                            PieChartData(
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 0,
                              centerSpaceRadius: 0,
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
                label: Text(
                  AppLocale.RegistrationRequests.getString(context),
                  style: widget.labelStyle,
                ),
              ),
              const SizedBox.square(dimension: 5),
              _ChartIndicator(
                color: Colors.blue,
                square: true,
                label: Text(
                  AppLocale.Residents.getString(context),
                  style: widget.labelStyle,
                ),
              ),
            ],
          ),
        ],
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
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.size.width < ScreenWidth.LARGE) {
      return const SizedBox.shrink();
    }

    _RegistrationRequestCount.instance?.reload();
    _ResidentCount.instance?.reload();
    _RoomCount.instance?.reload();

    const cardPadding = EdgeInsets.all(20);
    const numberStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    const labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final requestCounter = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: InkWell(
          onTap: () => pushNamed(context, ApplicationRoute.adminRegisterQueue),
          child: Padding(
            padding: cardPadding,
            child: RegistrationRequestCounter(
              state: state,
              numberStyle: numberStyle,
              labelStyle: labelStyle,
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
            padding: cardPadding,
            child: ResidentCounter(
              state: state,
              numberStyle: numberStyle,
              labelStyle: labelStyle,
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
            padding: cardPadding,
            child: RoomCounter(
              state: state,
              numberStyle: numberStyle,
              labelStyle: labelStyle,
            ),
          ),
        ),
      ),
    );
    final pieChart = Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: cardPadding,
          child: AccountsPieChart(state: state),
        ),
      ),
    );

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(child: requestCounter),
          Expanded(child: residentCounter),
          Expanded(child: roomCounter),
          Expanded(child: pieChart),
        ],
      ),
    );
  }
}

class AdminAccountSearchButton extends StatelessWidget {
  final String? Function() getName;
  final String? Function() getRoom;
  final String? Function() getUsername;
  final bool Function() getSearching;
  final void Function(String) setName;
  final void Function(String) setRoom;
  final void Function(String) setUsername;
  final void Function(int) setOffset;
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
    required this.setOffset,
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
            setOffset(0);

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

class PaginationButton extends StatelessWidget {
  final int offset;
  final int offsetLimit;
  final void Function(int) setOffset;
  final TextEditingController offsetController;

  PaginationButton({
    super.key,
    required this.offset,
    required this.offsetLimit,
    required this.setOffset,
  }) : offsetController = TextEditingController(text: (offset + 1).toString());

  void _onSubmit() {
    final page = int.tryParse(offsetController.text);
    if (page != null) {
      final newOffset = page - 1;
      if (newOffset >= 0 && newOffset <= offsetLimit) {
        setOffset(newOffset);
        return;
      }
    }

    // Invalid input, reset
    offsetController.text = (offset + 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_outlined),
          onPressed: () {
            if (offset > 0) {
              setOffset(offset - 1);
            }
          },
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: IntrinsicWidth(
            child: TextField(
              controller: offsetController,
              decoration: InputDecoration(suffixText: "/${offsetLimit + 1}", isCollapsed: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              maxLines: 1,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _onSubmit(),
              onTapOutside: (_) => _onSubmit(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_outlined),
          onPressed: () {
            if (offset < offsetLimit) {
              setOffset(offset + 1);
            }
          },
        ),
      ],
    );
  }
}
