import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const NzrNotifyApp());
}

class NzrNotifyApp extends StatefulWidget {
  const NzrNotifyApp({super.key});

  @override
  State<NzrNotifyApp> createState() => _NzrNotifyAppState();
}

class _NzrNotifyAppState extends State<NzrNotifyApp> {
  ThemeMode mode = ThemeMode.system;
  Color seed = const Color(0xFF7C3AED);

  void applyOrg(Map<String, dynamic> org) {
    final hex = (org['primary_color'] ?? '#7C3AED')
        .toString()
        .replaceAll('#', '');
    if (hex.length == 6) {
      seed = Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF7C3AED);
    }
    mode = switch (org['theme_mode']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    setState(() {});
  }

  ThemeData theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? const Color(0xFF0D0D12)
          : const Color(0xFFF7F7FB),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'sans',
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF14141B)
            : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: .15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF17171F)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.dark
            ? const Color(0xFF17171F)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .22),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noty Group',
      themeMode: mode,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: HomePage(onOrgChanged: applyOrg),
    );
  }
}

class HomePage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onOrgChanged;

  const HomePage({super.key, required this.onOrgChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  int? orgId;
  Map<String, dynamic>? org;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final orgs = await Api.getList('/api/organizations');
      if (orgs.isEmpty) {
        org = await Api.post('/api/organizations', {
          'name': 'Minha Igreja',
          'primary_color': '#7C3AED',
          'theme_mode': 'system',
        });
      } else {
        org = Map<String, dynamic>.from(orgs.first);
      }
      orgId = org!['id'] as int;
      widget.onOrgChanged(org!);
    } catch (_) {
      org = {
        'id': 1,
        'name': 'Minha Igreja',
        'primary_color': '#7C3AED',
        'theme_mode': 'system',
      };
      orgId = 1;
      widget.onOrgChanged(org!);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PremiumLoadingScreen();

    final pages = [
      Dashboard(orgId: orgId!, org: org!),
      EventsPage(orgId: orgId!),
      ContactsPage(orgId: orgId!),
      CampaignsPage(orgId: orgId!),
      SettingsPage(
        org: org!,
        onSaved: (o) {
          org = o;
          widget.onOrgChanged(o);
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              org: org!,
              onNotificationTap: () => _showInfo(
                context,
                'Central de alertas',
                'Aqui ficarão confirmações de envio, falhas, respostas e avisos importantes.',
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(.035, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Contatos',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Campanhas',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Map<String, dynamic> org;
  final VoidCallback onNotificationTap;

  const _TopBar({required this.org, required this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    final name = (org['name'] ?? 'Noty Group').toString();
    final logo = (org['logo_url'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 8),
      child: Row(
        children: [
          Hero(
            tag: 'org-logo',
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: logo.isNotEmpty
                  ? Image.network(
                      logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _OrgLetter(name: name),
                    )
                  : _OrgLetter(name: name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 6),
                    Text(
                      'Central ativa',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Alertas',
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _OrgLetter extends StatelessWidget {
  final String name;

  const _OrgLetter({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isEmpty ? 'N' : name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Container(
          width: 8 + (controller.value * 2),
          height: 8 + (controller.value * 2),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E)
                    .withValues(alpha: .16 + controller.value * .25),
                blurRadius: 5 + controller.value * 8,
                spreadRadius: controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class Dashboard extends StatefulWidget {
  final int orgId;
  final Map<String, dynamic> org;

  const Dashboard({super.key, required this.orgId, required this.org});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? stats;
  List<dynamic> upcoming = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      stats = await Api.getMap('/api/organizations/${widget.orgId}/stats');
      final events =
          await Api.getList('/api/organizations/${widget.orgId}/events');
      upcoming = events.take(3).toList();
    } catch (_) {
      stats = {
        'contacts': 248,
        'opted_in': 231,
        'upcoming_events': 4,
        'scheduled_campaigns': 7,
      };
      upcoming = [
        {
          'title': 'Culto de Celebração',
          'description': 'Uma noite de fé, louvor e palavra.',
          'starts_at': DateTime.now()
              .add(const Duration(days: 1, hours: 4))
              .toIso8601String(),
          'location_text': 'Templo principal',
          'banner_url': '',
        }
      ];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          _StaggeredItem(
            index: 0,
            child: _WelcomeHero(
              orgName: (widget.org['name'] ?? 'Sua organização').toString(),
            ),
          ),
          const SizedBox(height: 18),
          _StaggeredItem(
            index: 1,
            child: Row(
              children: [
                Text(
                  'Visão geral',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  'Hoje',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(
            index: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      width: width,
                      label: 'Contatos',
                      value: stats!['contacts'],
                      icon: Icons.groups_2_outlined,
                    ),
                    _StatCard(
                      width: width,
                      label: 'Autorizados',
                      value: stats!['opted_in'],
                      icon: Icons.verified_user_outlined,
                    ),
                    _StatCard(
                      width: width,
                      label: 'Próximos eventos',
                      value: stats!['upcoming_events'],
                      icon: Icons.event_available_outlined,
                    ),
                    _StatCard(
                      width: width,
                      label: 'Agendamentos',
                      value: stats!['scheduled_campaigns'],
                      icon: Icons.schedule_send_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _StaggeredItem(index: 3, child: const _WhatsAppStatusCard()),
          const SizedBox(height: 22),
          _StaggeredItem(
            index: 4,
            child: Text(
              'Ações rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(index: 5, child: const _QuickActions()),
          const SizedBox(height: 22),
          _StaggeredItem(
            index: 6,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Próximo evento',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StaggeredItem(
            index: 7,
            child: upcoming.isEmpty
                ? const _EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Nenhum evento próximo',
                    subtitle: 'Cadastre seu próximo culto ou evento.',
                  )
                : _EventHighlight(event: upcoming.first),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final String orgName;

  const _WelcomeHero({required this.orgName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Noty Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sua comunicação,\nmais perto das pessoas.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                orgName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final dynamic value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 850),
                tween: Tween(begin: 0, end: (value as num?)?.toDouble() ?? 0),
                curve: Curves.easeOutCubic,
                builder: (_, number, __) => Text(
                  number.round().toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppStatusCard extends StatelessWidget {
  const _WhatsAppStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withValues(alpha: .16),
            const Color(0xFF25D366).withValues(alpha: .05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WhatsApp principal',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Canal de avisos e lembretes automáticos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ATIVO',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.add_circle_outline_rounded, 'Novo evento'),
      (Icons.schedule_send_outlined, 'Agendar aviso'),
      (Icons.person_add_alt_1_outlined, 'Novo contato'),
      (Icons.image_outlined, 'Banner'),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Container(
              width: 112,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: .24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1,
                      size: 24, color: Theme.of(context).colorScheme.primary),
                  const Spacer(),
                  Text(
                    item.$2,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventHighlight extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventHighlight({required this.event});

  @override
  Widget build(BuildContext context) {
    final title = (event['title'] ?? 'Próximo evento').toString();
    final description = (event['description'] ?? '').toString();
    final location = (event['location_text'] ?? '').toString();
    final banner = (event['banner_url'] ?? '').toString();
    DateTime? date;
    try {
      date = DateTime.parse((event['starts_at'] ?? '').toString()).toLocal();
    } catch (_) {}

    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 245,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: .92),
              scheme.tertiary.withValues(alpha: .88),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.isNotEmpty)
              Image.network(
                banner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .04),
                    Colors.black.withValues(alpha: .72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        DateFormat("dd/MM • HH:mm").format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventsPage extends StatefulWidget {
  final int orgId;

  const EventsPage({super.key, required this.orgId});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      items = await Api.getList('/api/organizations/${widget.orgId}/events');
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final banner = TextEditingController();
    final local = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 1));

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _PremiumSheet(
        title: 'Novo culto ou evento',
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: banner,
              decoration: const InputDecoration(
                labelText: 'URL do banner',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: local,
              decoration: const InputDecoration(
                labelText: 'Local',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _InfoPill(
              icon: Icons.schedule_rounded,
              text: DateFormat('dd/MM/yyyy • HH:mm').format(date),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Criar evento'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && title.text.trim().isNotEmpty) {
      try {
        await Api.post('/api/organizations/${widget.orgId}/events', {
          'title': title.text.trim(),
          'description': description.text,
          'banner_url': banner.text,
          'location_text': local.text,
          'starts_at': date.toUtc().toIso8601String(),
          'reminder_minutes': [1440, 180, 60],
        });
        await load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backend ainda não está conectado.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                children: [
                  _PageTitle(
                    eyebrow: 'AGENDA',
                    title: 'Cultos e eventos',
                    subtitle:
                        'Organize banners, horários, locais e lembretes automáticos.',
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const _EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'Sua agenda está vazia',
                      subtitle:
                          'Crie um evento e programe avisos automáticos para o WhatsApp.',
                    )
                  else
                    for (var i = 0; i < items.length; i++)
                      _StaggeredItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EventListCard(event: items[i]),
                        ),
                      ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo evento'),
      ),
    );
  }
}

class _EventListCard extends StatelessWidget {
  final dynamic event;

  const _EventListCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final banner = (event['banner_url'] ?? '').toString();
    final title = (event['title'] ?? '').toString();
    final description = (event['description'] ?? '').toString();
    final start = (event['starts_at'] ?? '').toString();

    DateTime? date;
    try {
      date = DateTime.parse(start).toLocal();
    } catch (_) {}

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.isNotEmpty)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(
                banner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .08),
                  child: const Center(child: Icon(Icons.image_outlined)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date == null ? '--' : DateFormat('dd').format(date),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        date == null
                            ? '---'
                            : DateFormat('MMM', 'pt_BR')
                                .format(date)
                                .toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  final int orgId;

  const ContactsPage({super.key, required this.orgId});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      items = await Api.getList('/api/organizations/${widget.orgId}/contacts');
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    bool opt = true;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => _PremiumSheet(
          title: 'Novo contato',
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone com DDI',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: opt,
                onChanged: (v) => setS(() => opt = v),
                title: const Text('Autorizou receber avisos'),
                subtitle: const Text('Consentimento para mensagens automáticas'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.pop(c, true),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Adicionar contato'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && phone.text.trim().isNotEmpty) {
      try {
        await Api.post('/api/organizations/${widget.orgId}/contacts', {
          'name': name.text,
          'phone': phone.text,
          'segment': 'Todos',
          'opt_in': opt,
        });
        await load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backend ainda não está conectado.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                children: [
                  const _PageTitle(
                    eyebrow: 'PÚBLICO',
                    title: 'Contatos',
                    subtitle:
                        'Organize quem recebe seus avisos e segmente sua comunicação.',
                  ),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const _EmptyState(
                      icon: Icons.groups_2_outlined,
                      title: 'Nenhum contato por aqui',
                      subtitle:
                          'Cadastre contatos com autorização para receber notificações.',
                    )
                  else
                    for (var i = 0; i < items.length; i++)
                      _StaggeredItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ContactCard(contact: items[i]),
                        ),
                      ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Adicionar'),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final dynamic contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final name = (contact['name'] ?? 'Contato').toString();
    final phone = (contact['phone'] ?? '').toString();
    final segment = (contact['segment'] ?? 'Todos').toString();
    final opted = contact['opt_in'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: .12),
              child: Text(
                name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '$phone • $segment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: (opted ? const Color(0xFF22C55E) : Colors.red)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opted ? 'ATIVO' : 'SEM OPT-IN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: opted ? const Color(0xFF16A34A) : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampaignsPage extends StatefulWidget {
  final int orgId;

  const CampaignsPage({super.key, required this.orgId});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      items = await Api.getList('/api/organizations/${widget.orgId}/campaigns');
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> add() async {
    final title = TextEditingController(text: 'Hoje tem culto!');
    final body = TextEditingController(
      text: 'Esperamos você. Confira o horário e participe conosco.',
    );

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => _PremiumSheet(
        title: 'Agendar aviso',
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.campaign_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: body,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensagem',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoPill(
              icon: Icons.schedule_rounded,
              text: 'Nesta V1 será agendado para daqui a 5 minutos',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.schedule_send_rounded),
              label: const Text('Agendar campanha'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      try {
        await Api.post('/api/organizations/${widget.orgId}/campaigns', {
          'title': title.text,
          'body': body.text,
          'segment': 'Todos',
          'scheduled_for': DateTime.now()
              .add(const Duration(minutes: 5))
              .toUtc()
              .toIso8601String(),
          'channel': 'whatsapp_dm',
        });
        await load();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backend ainda não está conectado.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                children: [
                  const _PageTitle(
                    eyebrow: 'WHATSAPP',
                    title: 'Campanhas',
                    subtitle:
                        'Crie avisos, lembretes e divulgações com agendamento automático.',
                  ),
                  const SizedBox(height: 18),
                  const _WhatsAppPreviewCard(),
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    const _EmptyState(
                      icon: Icons.schedule_send_outlined,
                      title: 'Nenhuma campanha',
                      subtitle:
                          'Agende um aviso para os contatos que autorizaram receber mensagens.',
                    )
                  else
                    for (var i = 0; i < items.length; i++)
                      _StaggeredItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CampaignCard(campaign: items[i]),
                        ),
                      ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Agendar'),
      ),
    );
  }
}

class _WhatsAppPreviewCard extends StatelessWidget {
  const _WhatsAppPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF101A15)
            : const Color(0xFFEFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: .22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              SizedBox(width: 8),
              Text(
                'Prévia no WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoje tem culto! 🙏',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Esperamos você. Toque para conferir o horário e a localização.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final dynamic campaign;

  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final title = (campaign['title'] ?? '').toString();
    final status = (campaign['status'] ?? 'scheduled').toString();
    final scheduled = (campaign['scheduled_for'] ?? '').toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '$status • $scheduled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  Map<String, dynamic> org;
  final ValueChanged<Map<String, dynamic>> onSaved;

  SettingsPage({super.key, required this.org, required this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController name;
  late TextEditingController color;
  late TextEditingController logo;
  late TextEditingController phone;
  late String mode;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.org['name'] ?? '');
    color =
        TextEditingController(text: widget.org['primary_color'] ?? '#7C3AED');
    logo = TextEditingController(text: widget.org['logo_url'] ?? '');
    phone = TextEditingController(text: widget.org['whatsapp_phone'] ?? '');
    mode = widget.org['theme_mode'] ?? 'system';
  }

  @override
  void dispose() {
    name.dispose();
    color.dispose();
    logo.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final optimistic = {
      ...widget.org,
      'name': name.text,
      'logo_url': logo.text,
      'primary_color': color.text,
      'theme_mode': mode,
      'whatsapp_phone': phone.text,
    };

    try {
      final o = await Api.patch('/api/organizations/${widget.org['id']}', {
        'name': name.text,
        'logo_url': logo.text,
        'primary_color': color.text,
        'theme_mode': mode,
        'whatsapp_phone': phone.text,
      });
      widget.onSaved(o);
    } catch (_) {
      widget.onSaved(optimistic);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações aplicadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
      children: [
        const _PageTitle(
          eyebrow: 'PERSONALIZAÇÃO',
          title: 'Sua identidade',
          subtitle:
              'Cada igreja ou empresa pode ter sua própria marca e experiência visual.',
        ),
        const SizedBox(height: 18),
        _BrandPreview(
          name: name.text.isEmpty ? 'Minha Igreja' : name.text,
          logo: logo.text,
          colorHex: color.text,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: name,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nome da igreja/empresa',
            prefixIcon: Icon(Icons.apartment_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: logo,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'URL da logo',
            prefixIcon: Icon(Icons.image_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: color,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Cor principal (#7C3AED)',
            prefixIcon: Icon(Icons.palette_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número WhatsApp Business',
            prefixIcon: Icon(Icons.chat_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: mode,
          decoration: const InputDecoration(
            labelText: 'Tema',
            prefixIcon: Icon(Icons.brightness_6_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('Automático')),
            DropdownMenuItem(value: 'light', child: Text('Claro')),
            DropdownMenuItem(value: 'dark', child: Text('Escuro')),
          ],
          onChanged: (v) => setState(() => mode = v ?? 'system'),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar identidade'),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text(
              'Ambientes isolados',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Contatos, eventos, campanhas e configurações ficam separados por organização.',
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPreview extends StatelessWidget {
  final String name;
  final String logo;
  final String colorHex;

  const _BrandPreview({
    required this.name,
    required this.logo,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final clean = colorHex.replaceAll('#', '');
    final color = clean.length == 6
        ? Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF7C3AED)
        : const Color(0xFF7C3AED);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, .18)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: logo.isEmpty
                ? Center(
                    child: Text(
                      name.isEmpty ? 'N' : name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  )
                : Image.network(
                    logo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Identidade personalizada',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _PageTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _PremiumSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: .96),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: .28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 90 + index * 55);
    return TweenAnimationBuilder<double>(
      duration: delay + const Duration(milliseconds: 380),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        final normalized = ((value * 1.25) - .25).clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: normalized,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - normalized)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _PremiumLoadingScreen extends StatefulWidget {
  const _PremiumLoadingScreen();

  @override
  State<_PremiumLoadingScreen> createState() => _PremiumLoadingScreenState();
}

class _PremiumLoadingScreenState extends State<_PremiumLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final scale = 1 + controller.value * .05;
            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .20 + controller.value * .15),
                          blurRadius: 30,
                          spreadRadius: controller.value * 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Noty Group',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Preparando sua central…',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showInfo(BuildContext context, String title, String body) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (c) => _PremiumSheet(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Entendi'),
          ),
        ],
      ),
    ),
  );
}
