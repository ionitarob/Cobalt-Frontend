import 'package:flutter/material.dart';

enum NavSection { proyectos, herramientas }

class NavChild {
  final String label;
  final String route;
  const NavChild({required this.label, required this.route});
}

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final NavSection section;
  final List<NavChild> children;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.section,
    this.children = const [],
  });
}

const List<NavItem> kNavItems = [
  NavItem(
    label: 'Ordenes CF',
    icon: Icons.assignment_outlined,
    route: '/home/ordenes-cf',
    section: NavSection.proyectos,
  ),
  NavItem(
    label: 'Amazon',
    icon: Icons.local_shipping_outlined,
    route: '/home/amazon',
    section: NavSection.proyectos,
  ),
  NavItem(
    label: 'Análisis y Servicios',
    icon: Icons.analytics_outlined,
    route: '/home/analisis',
    section: NavSection.proyectos,
  ),
  NavItem(
    label: 'Xiaomi y Serials',
    icon: Icons.devices_outlined,
    route: '/home/xiaomi',
    section: NavSection.proyectos,
    children: [
      NavChild(label: 'Cambio de Serials', route: '/home/xiaomi/cambio-serials'),
      NavChild(label: 'Historial Serials', route: '/home/xiaomi/historial-serials'),
    ],
  ),
  NavItem(
    label: 'Revisión TV',
    icon: Icons.tv_outlined,
    route: '/home/revision-tv',
    section: NavSection.herramientas,
  ),
  NavItem(
    label: 'Servidores',
    icon: Icons.dns_outlined,
    route: '/home/servidores',
    section: NavSection.herramientas,
  ),
  NavItem(
    label: 'Sentinel AI',
    icon: Icons.psychology_outlined,
    route: '/home/sentinel',
    section: NavSection.herramientas,
  ),
  NavItem(
    label: 'Bartender Labels',
    icon: Icons.label_outlined,
    route: '/home/bartender',
    section: NavSection.herramientas,
  ),
];
