import 'package:flutter/material.dart';

class DeviceButton {
  final String label;
  final String route;
  final IconData? icon;

  const DeviceButton({required this.label, required this.route, this.icon});
}

const List<DeviceButton> deviceButons = [
  DeviceButton(label: "Luces", route: "/light", icon: Icons.lightbulb_outline),
  DeviceButton(label: "Aire acondicionado", route: "/air", icon: Icons.ac_unit),
  DeviceButton(label: "Dispositivos", route: "/devices", icon: Icons.devices),
  //DeviceButton(label: "Consumo", route: "/devices", icon: Icons.auto_graph_sharp),
];
