import 'package:flutter/material.dart';

import '../../../models/tournament.dart';
import 'bracket_tree_view.dart';

/// Tournament match tree section — delegates to [BracketTreeView].
class BracketView extends StatelessWidget {
  const BracketView({super.key, required this.matches});

  final List<BracketMatch> matches;

  @override
  Widget build(BuildContext context) {
    return BracketTreeView(matches: matches);
  }
}
