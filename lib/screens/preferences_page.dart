import 'package:flutter/material.dart';
import 'package:trashit/services/user_profile_service.dart';
import 'package:trashit/services/theme_service.dart';
import 'package:trashit/theme.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _loading = true;
  bool _analyticsConsent = false;
  bool _demographicsConsent = false;
  String? _ageBand;
  String? _gender;
  String? _region;

  // Appearance
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeVariant _themeVariant = AppThemeVariant.red;
  final _ageBands = const [
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
    'Prefer not to say',
  ];

  final _genders = const [
    'female',
    'male',
    'nonbinary',
    'other',
    'prefer_not',
  ];

  final _regions = const [
    'US', 'EU', 'UK', 'IN', 'SEA', 'LATAM', 'MENA', 'AFR', 'APAC', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await UserProfileService.load();
    final themeSvc = ThemeService.instance;
    setState(() {
      _analyticsConsent = profile.analyticsConsent;
      _demographicsConsent = profile.demographicsConsent;
      _ageBand = profile.ageBand;
      _gender = profile.gender;
      _region = profile.region;
      // theme
      _themeMode = themeSvc.mode;
      _themeVariant = themeSvc.variant;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final profile = UserProfile(
      analyticsConsent: _analyticsConsent,
      demographicsConsent: _demographicsConsent,
      ageBand: _demographicsConsent ? _ageBand : null,
      gender: _demographicsConsent ? _gender : null,
      region: _demographicsConsent ? _region : null,
    );
    await UserProfileService.save(profile);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences & Privacy'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'Appearance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme mode', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('System'),
                            selected: _themeMode == ThemeMode.system,
                            onSelected: (s) {
                              if (s) {
                                setState(() => _themeMode = ThemeMode.system);
                                ThemeService.instance.setMode(ThemeMode.system);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Light'),
                            selected: _themeMode == ThemeMode.light,
                            onSelected: (s) {
                              if (s) {
                                setState(() => _themeMode = ThemeMode.light);
                                ThemeService.instance.setMode(ThemeMode.light);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Dark'),
                            selected: _themeMode == ThemeMode.dark,
                            onSelected: (s) {
                              if (s) {
                                setState(() => _themeMode = ThemeMode.dark);
                                ThemeService.instance.setMode(ThemeMode.dark);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Color palette', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      _PalettePicker(
                        value: _themeVariant,
                        onChanged: (v) {
                          setState(() => _themeVariant = v);
                          ThemeService.instance.setVariant(v);
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _themeVariant = AppThemeVariant.red);
                          ThemeService.instance.setVariant(AppThemeVariant.red);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Revert to Red (original)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Privacy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        value: _analyticsConsent,
                        onChanged: (v) => setState(() => _analyticsConsent = v),
                        title: const Text('Allow anonymous analytics'),
                        subtitle: const Text('Helps us improve features and understand engagement. No account required.'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _demographicsConsent,
                        onChanged: _analyticsConsent ? (v) => setState(() => _demographicsConsent = v) : null,
                        title: const Text('Share optional demographics'),
                        subtitle: const Text('Voluntary, coarse-grained info (age band, gender, region). Used only in aggregate.'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'We do not collect ethnicity. Sensitive traits should not be used to target content. You can revoke consent anytime.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_demographicsConsent && _analyticsConsent) _Section(
                  title: 'Demographics (optional)',
                  child: Column(
                    children: [
                      _DropdownField(
                        label: 'Age band',
                        value: _ageBand,
                        items: _ageBands,
                        onChanged: (v) => setState(() => _ageBand = v),
                      ),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Gender',
                        value: _gender,
                        items: _genders,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 8),
                      _DropdownField(
                        label: 'Region',
                        value: _region,
                        items: _regions,
                        onChanged: (v) => setState(() => _region = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
    );
  }
}


class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            // We allow a null sentinel option with a readable label
            DropdownMenuItem<String>(value: null, child: Text('Select...'.toString())),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  final AppThemeVariant value;
  final ValueChanged<AppThemeVariant> onChanged;
  const _PalettePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final schemes = <AppThemeVariant, String>{
      AppThemeVariant.red: 'Red (original)',
      AppThemeVariant.crimson: 'Crimson',
      AppThemeVariant.slate: 'Slate',
      AppThemeVariant.ocean: 'Ocean',
      AppThemeVariant.violet: 'Violet',
      AppThemeVariant.forest: 'Forest',
      AppThemeVariant.sunset: 'Sunset',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: schemes.entries.map((e) {
        final isSelected = e.key == value;
        return ChoiceChip(
          label: Text(e.value),
          selected: isSelected,
          onSelected: (_) => onChanged(e.key),
        );
      }).toList(),
    );
  }
}
