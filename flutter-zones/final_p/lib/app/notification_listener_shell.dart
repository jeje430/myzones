import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/notifications/bloc/notification_bloc.dart';
import '../features/notifications/bloc/notification_event.dart';
import '../features/notifications/bloc/notification_state.dart';
import '../features/notifications/models/push_message.dart';
import '../features/notifications/widgets/foreground_notification_banner.dart';
import '../screens/tournaments/customer_tournament_bracket_screen.dart';

class NotificationListenerShell extends StatelessWidget {
  const NotificationListenerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationNavigate) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomerTournamentBracketScreen(
                tournamentId: state.target.tournamentId,
                tournamentTitle: state.target.tournamentTitle,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return Stack(
            alignment: Alignment.topLeft,
            children: [
              child,
              if (state is NotificationForegroundBanner)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ForegroundNotificationBanner(
                    message: state.message,
                    onDismiss: () {
                      context.read<NotificationBloc>().add(
                            const NotificationDismissed(),
                          );
                    },
                    onTap: () {
                      final target = _targetFromMessage(state.message);
                      if (target != null) {
                        context.read<NotificationBloc>().add(
                              NotificationNavigateRequested(target),
                            );
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PushNavigationTarget? _targetFromMessage(PushMessage message) {
    if (message.data['type'] != 'tournament_winner') return null;
    final id = message.data['tournament_id'];
    if (id == null || id.isEmpty) return null;
    return PushNavigationTarget(
      tournamentId: id,
      tournamentTitle: message.data['tournament_title'] ?? 'البطولة',
    );
  }
}
