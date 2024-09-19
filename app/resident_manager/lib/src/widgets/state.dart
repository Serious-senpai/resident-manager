import "package:flutter/material.dart";

import "../core/state.dart";

abstract class StateAwareWidget extends StatefulWidget {
  abstract final ApplicationState state;

  const StateAwareWidget({super.key});
}
