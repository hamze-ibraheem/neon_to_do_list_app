import 'dart:convert';
import 'package:neon_framework/neon.dart';
import '../state/todo_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  NeonState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends NeonState<SettingsScreen> {
  final TodoStore _store = TodoStore.instance;
  String? _exportedSnapshotPreview;

  void _exportRouterSnapshot() {
    final router = NeonRouter.of(context);
    final snapshot = router.exportSnapshot();
    setState(() {
      _exportedSnapshotPreview = const JsonEncoder.withIndent('  ').convert(snapshot);
    });
  }

  void _resetAllData() {
    _store.resetSampleData();
    setState(() {
      _exportedSnapshotPreview = 'Sample tasks reset successfully.';
    });
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        // Main Scrollable Area
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const NeonEdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Settings & Engine Diagnostics',
                    style: NeonTextStyle(
                      fontSize: 24,
                      fontWeight: NeonFontWeight.bold,
                      color: NeonColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Widget Tree Diffing Card
                  Card(
                    padding: const NeonEdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Widget Tree Diffing',
                              style: NeonTextStyle(
                                fontSize: 16,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor.textPrimary,
                              ),
                            ),
                            Spacer(),
                            Badge(
                              backgroundColor: NeonColor.success,
                              label: Text('RFC-6902 Active'),
                              child: SizedBox(width: 0, height: 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Neon compares widget tree revisions and sends incremental JSON patches over the HTTP bridge rather than serializing the entire tree on every keystroke.',
                          style: NeonTextStyle(
                            fontSize: 13,
                            color: NeonColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              'Incremental Diffing Enabled',
                              style: NeonTextStyle(
                                fontSize: 14,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              key: 'switch_diffing_toggle',
                              value: _store.diffingEnabled.value,
                              onChanged: (val) {
                                setState(() {
                                  _store.diffingEnabled.value = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation State & Snapshots Card
                  Card(
                    padding: const NeonEdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigation Router Diagnostics',
                          style: NeonTextStyle(
                            fontSize: 16,
                            fontWeight: NeonFontWeight.bold,
                            color: NeonColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Export the current 100% JSON-serializable navigation history, active route, and parameters for time-travel debugging or process restoration.',
                          style: NeonTextStyle(
                            fontSize: 13,
                            color: NeonColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            FilledButton(
                              key: 'btn_export_snapshot',
                              color: NeonColor.primary,
                              child: const Text(
                                'Export Snapshot',
                                style: NeonTextStyle(
                                  color: NeonColor.white,
                                  fontWeight: NeonFontWeight.bold,
                                ),
                              ),
                              onPressed: _exportRouterSnapshot,
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              key: 'btn_reset_sample',
                              color: const NeonColor(0xFF64748B),
                              child: const Text(
                                'Reset Tasks',
                                style: NeonTextStyle(
                                  color: NeonColor.white,
                                  fontWeight: NeonFontWeight.bold,
                                ),
                              ),
                              onPressed: _resetAllData,
                            ),
                          ],
                        ),
                        if (_exportedSnapshotPreview != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const NeonEdgeInsets.all(12),
                            color: const NeonColor(0x0C000000),
                            child: Text(
                              _exportedSnapshotPreview!,
                              style: const NeonTextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // About Neon Framework Card
                  const Card(
                    padding: NeonEdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Neon Framework',
                              style: NeonTextStyle(
                                fontSize: 16,
                                fontWeight: NeonFontWeight.bold,
                                color: NeonColor.textPrimary,
                              ),
                            ),
                            Spacer(),
                            Badge(
                              backgroundColor: NeonColor.primary,
                              label: Text('v0.1.0-alpha'),
                              child: SizedBox(width: 0, height: 0),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Standalone mobile UI framework with pure Dart backend, JSON tree diffing engine, and native Android (Kotlin) / iOS (UIKit) platform shells.',
                          style: NeonTextStyle(
                            fontSize: 13,
                            color: NeonColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // Permanently Docked Bottom Navigation Bar
        NavigationBar(
          selectedIndex: 2,
          onDestinationSelected: (idx) {
            if (idx == 0) NeonRouter.of(context).replace('/tasks');
            if (idx == 1) NeonRouter.of(context).replace('/analytics');
            if (idx == 2) NeonRouter.of(context).replace('/settings');
          },
          destinations: const [
            NavigationDestination(icon: Text('📋'), label: 'Tasks'),
            NavigationDestination(icon: Text('📊'), label: 'Analytics'),
            NavigationDestination(icon: Text('⚙️'), label: 'Settings'),
          ],
        ),
      ],
    );
  }
}
