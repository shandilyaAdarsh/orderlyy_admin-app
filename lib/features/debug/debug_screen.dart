import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  static const _routes = [
    ('/splash', 'Splash Screen', Icons.play_circle_rounded),
    ('/admin/login', 'Admin Login', Icons.admin_panel_settings_rounded),
    ('/admin/dashboard', 'Admin Dashboard', Icons.dashboard_rounded),
    ('/admin/orders', 'Admin Live Orders', Icons.receipt_long_rounded),
    ('/admin/inventory', 'Admin Inventory', Icons.inventory_2_rounded),
    ('/admin/analytics', 'Admin Analytics', Icons.bar_chart_rounded),
    ('/admin/profile', 'Admin Profile', Icons.person_rounded),
    ('/admin/settings', 'App Settings', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC0272D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEBUG',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Screen Navigator',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1D),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _routes.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade100,
          thickness: 1,
          height: 1,
          indent: 60,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final (route, label, icon) = _routes[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFC0272D), size: 20),
            ),
            title: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191C1D),
              ),
            ),
            subtitle: Text(
              route,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC0272D),
              size: 20,
            ),
            onTap: () => context.go(route),
          );
        },
      ),
    );
  }
}
