import 'package:flutter/material.dart';

import '../../core/auth_service.dart';
import '../../core/cobalt_theme.dart';
import '../../core/colors.dart';
import 'sheets/template_manager.dart';
import 'tabs/aprovisionamiento_tab.dart';
import 'tabs/my_tasks_tab.dart';
import 'tabs/orders_tab.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _templatePanelOpen = false;

  bool get _isAdmin {
    final role = AuthService.instance.currentUser?.role;
    return role == 'admin' || role == 'superadmin';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Material(
      color: ct.background,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _screenHeader(ct),
              _tabBar(),
              Divider(height: 1, color: ct.border),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    OrdersTab(isAdmin: _isAdmin),
                    const AprovisionamientoTab(),
                    const MyTasksTab(),
                  ],
                ),
              ),
            ],
          ),
          // Template manager slide-in
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            right: _templatePanelOpen ? 0 : -720,
            top: 0,
            bottom: 0,
            child: _templatePanelOpen
                ? TemplateManager(
                    onClose: () => setState(() => _templatePanelOpen = false))
                : const SizedBox(width: 0),
          ),
        ],
      ),
    );
  }

  Widget _screenHeader(CobaltPalette ct) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ct.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Órdenes CF',
              style: TextStyle(
                  color: ct.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_isAdmin)
            _HeaderAction(
              icon: Icons.checklist_rounded,
              label: 'Plantillas',
              onTap: () => setState(() => _templatePanelOpen = !_templatePanelOpen),
            ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabs,
        isScrollable: false,
        indicatorColor: CobaltColors.cobaltLight,
        indicatorWeight: 2,
        labelColor: CobaltColors.cobaltLight,
        unselectedLabelColor: context.ct.textHint,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Órdenes'),
          Tab(text: 'Aprovisionamiento'),
          Tab(text: 'Mis tareas'),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? CobaltColors.cobalt.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: _hovered ? CobaltColors.cobalt : ct.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: CobaltColors.cobaltLight),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                      color: CobaltColors.cobaltLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
