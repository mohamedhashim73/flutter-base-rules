import 'package:base/core/widgets/data_state_widgets/loading_view_widget.dart';
import 'package:base/core/enums/request_status_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialogContentWidget<C extends Cubit<S>, S> extends StatefulWidget {
  final C cubit;
  final WidgetBuilder builder;
  final RequestStatus Function(S state) statusOf;
  final VoidCallback? onInit;
  final VoidCallback? onDispose;

  const DialogContentWidget({
    super.key,
    required this.cubit,
    required this.builder,
    required this.statusOf,
    this.onInit,
    this.onDispose,
  });

  @override
  State<DialogContentWidget<C, S>> createState() =>
      _DialogContentWidgetState<C, S>();
}

class _DialogContentWidgetState<C extends Cubit<S>, S>
    extends State<DialogContentWidget<C, S>> {
  // Tracks whether the cubit has entered loading state at least once.
  // Once loading starts the form is replaced with LoadingViewWidget and
  // never rebuilt back — this removes the TextFormField (and its
  // TextEditingController references) from the tree before the dialog
  // starts its exit animation, preventing the disposed-controller crash.
  bool _loadingStarted = false;

  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, S>(
      bloc: widget.cubit,
      buildWhen: (previous, current) {
        // Once loading has started, never rebuild back to the form.
        if (_loadingStarted) return false;
        return true;
      },
      builder: (context, state) {
        if (widget.statusOf(state) == RequestStatus.loading) {
          _loadingStarted = true;
          return const LoadingViewWidget();
        }
        return widget.builder(context);
      },
    );
  }
}
