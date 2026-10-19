import '../index.dart';

class ThemeChangeRoute extends StatelessWidget {
  const ThemeChangeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();
    final scheme = Theme.of(context).colorScheme;
    final colors = Global.themes;

    return Scaffold(
      appBar: AppBar(title: const Text('主题')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text('主题颜色', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '选择主题颜色。',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          ...colors.map(
            (color) => _ThemePreviewCard(
              color: color,
              selected: color.toARGB32() == themeModel.seedColor.toARGB32(),
              onTap: () => context.read<ThemeModel>().theme = color,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = ColorScheme.fromSeed(
      seedColor: color,
      brightness: theme.brightness,
    );
    final title = _colorName(color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: '选择$title',
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Ink(
                  height: 84,
                  width: double.infinity,
                  color: preview.primaryContainer,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: preview.primary,
                        child: Icon(Icons.code, color: preview.onPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gitee',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: preview.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          color: preview.onPrimaryContainer,
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(backgroundColor: color, radius: 10),
                  title: Text(title),
                  subtitle: Text(
                    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  ),
                  trailing: selected
                      ? Icon(Icons.radio_button_checked, color: scheme.primary)
                      : const Icon(Icons.radio_button_unchecked),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _colorName(Color value) {
    const names = <int, String>{
      0xff2196f3: '蓝色',
      0xff00bcd4: '青色',
      0xff009688: '蓝绿色',
      0xff4caf50: '绿色',
      0xfff44336: '红色',
    };
    return names[value.toARGB32()] ?? '自定义主题色';
  }
}
