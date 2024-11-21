import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:one_clock/one_clock.dart";
import "package:resident_manager/src/routes.dart";

import "../common.dart";
import "../state.dart";
import "../../translations.dart";
import "../../utils.dart";

class AdminHomePage extends StateAwareWidget {
  const AdminHomePage({super.key, required super.state});

  @override
  AbstractCommonState<AdminHomePage> createState() => _AdminHomePageState();
}

class _CardBuilder {
  final Color? backgroundColor;
  final void Function()? onPressed;
  final List<Widget> children;

  _CardBuilder({this.backgroundColor, this.onPressed, required this.children});

  Widget call(int flex) {
    return Builder(
      builder: (context) {
        return _ShrinkableFlex(
          flex: flex,
          child: Container(
            padding: const EdgeInsets.all(5),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClockAnimation {
  final AnimationController _clockAnimationController;
  final Animation<int> _clockAnimation;

  _ClockAnimation(AnimationController controller)
      : _clockAnimationController = controller,
        _clockAnimation = IntTween(begin: 0, end: 100).animate(controller);

  AnimationController get controller => _clockAnimationController;
  int get value => _clockAnimation.value;

  void dispose() {
    _clockAnimationController.dispose();
  }
}

class _ShrinkableFlex extends StatelessWidget {
  final int flex;
  final Widget child;

  const _ShrinkableFlex({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) {
    return flex == 0
        ? const SizedBox.shrink()
        : Expanded(
            flex: flex,
            child: child,
          );
  }
}

class _AdminHomePageState extends AbstractCommonState<AdminHomePage> with CommonStateMixin<AdminHomePage>, SingleTickerProviderStateMixin {
  _ClockAnimation? _clockAnimation;

  final _rowFlex = [
    [100, 200],
    [200, 100],
  ];
  final _columnFlex = [100, 100];

  @override
  void initState() {
    super.initState();
    _clockAnimation = _ClockAnimation(
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
        ..addListener(
          () {
            final value = _clockAnimation?.value;
            if (value != null) {
              _rowFlex[0][0] = 100 + 2 * value;
              _rowFlex[0][1] = 200 - 2 * value;
              _rowFlex[1][0] = 200 + value;
              _rowFlex[1][1] = 100 - value;
              _columnFlex[0] = 100 + value;
              _columnFlex[1] = 100 - value;
            }

            refresh();
          },
        ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _clockAnimation?.dispose();
  }

  @override
  CommonScaffold<AdminHomePage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Home.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Builder(
            builder: (context) {
              // Guess the appropriate clock size from the viewport
              final clockSize = mediaQuery.size.height / 2 - 100;
              final titleSize = mediaQuery.size.width > ScreenWidth.MEDIUM ? 24.0 : 20.0;
              final cards = [
                [
                  _CardBuilder(
                    backgroundColor: const Color(0xFF1E88E5),
                    onPressed: () {
                      final controller = _clockAnimation?.controller;
                      if (controller != null) {
                        if (controller.isCompleted) {
                          controller.reverse();
                        } else {
                          controller.forward();
                        }
                      }
                    },
                    children: [
                      AnalogClock(
                        datetime: DateTime.now(),
                        digitalClockColor: Colors.white,
                        hourHandColor: const Color(0xFF212121),
                        minuteHandColor: const Color(0xFFFFC107),
                        secondHandColor: const Color(0xFFFF5252),
                        numberColor: Colors.white,
                        tickColor: Colors.white,
                        height: clockSize,
                        isLive: true,
                        width: clockSize,
                      ),
                    ],
                  ),
                  _CardBuilder(
                    backgroundColor: const Color(0xFF43A047),
                    onPressed: () => pushNamedAndRefresh(context, ApplicationRoute.adminRegisterQueue),
                    children: (_clockAnimation?.controller.isAnimating ?? false)
                        ? []
                        : [
                            Icon(
                              Icons.how_to_reg_outlined,
                              size: titleSize,
                              color: Colors.white,
                            ),
                            Text(
                              AppLocale.RegisterQueue.getString(context),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                  ),
                ],
                [
                  _CardBuilder(
                    backgroundColor: const Color(0xFFFFB300),
                    onPressed: () => pushNamedAndRefresh(context, ApplicationRoute.adminResidentsPage),
                    children: (_clockAnimation?.controller.isAnimating ?? false)
                        ? []
                        : [
                            Icon(
                              Icons.people_outlined,
                              size: titleSize,
                              color: const Color(0xFF212121),
                            ),
                            Text(
                              AppLocale.ResidentsList.getString(context),
                              style: TextStyle(
                                color: const Color(0xFF212121),
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                  ),
                  _CardBuilder(
                    backgroundColor: const Color(0xFFD32F2F),
                    onPressed: () => pushNamedAndRefresh(context, ApplicationRoute.adminRoomsPage),
                    children: (_clockAnimation?.controller.isAnimating ?? false)
                        ? []
                        : [
                            Icon(
                              Icons.room_outlined,
                              size: titleSize,
                              color: Colors.white,
                            ),
                            Text(
                              AppLocale.RoomsList.getString(context),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                  ),
                ],
              ];

              final grid = mediaQuery.size.width > ScreenWidth.SMALL
                  ? List<List<Widget>>.generate(
                      2,
                      (i) => List<Widget>.generate(
                        2,
                        (j) => cards[i][j](_rowFlex[i][j]),
                      ),
                    )
                  : [
                      [cards[0][1](1)],
                      [cards[1][0](1)],
                      [cards[1][1](1)],
                    ];

              return Column(
                children: List<Widget>.generate(
                  grid.length,
                  (i) => _ShrinkableFlex(
                    flex: mediaQuery.size.width > ScreenWidth.SMALL ? _columnFlex[i] : 1,
                    child: Row(children: grid[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
