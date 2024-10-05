import "package:flutter/material.dart";

import "../state.dart";

abstract class StateAwareWidget extends StatefulWidget {
  final ApplicationState state;

  const StateAwareWidget({super.key, required this.state});
}
