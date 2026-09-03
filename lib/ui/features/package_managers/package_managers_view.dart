import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../../data/services/package_manager_service.dart';

class PackageManagersView extends StatefulWidget {
  const PackageManagersView({super.key});

  @override
  State<PackageManagersView> createState() => _PackageManagersViewState();
}

class _PackageManagersViewState extends State<PackageManagersView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<PackageItem> _results = [];
  bool _isLoading = false;
  String _selectedSource = 'all'; // 'all' | 'winget' | 'chocolatey'
  String? _statusLog;
  final Map<String, bool> _installing = {};

  bool _hasWinget = false;
  bool _hasChoco = false;

  final List<PackageItem> _curatedQuickPackages = [
    PackageItem(id: 'Git.Git', name: 'Git', version: 'Latest', source: 'winget'),
    PackageItem(id: '7zip.7zip', name: '7-Zip', version: 'Latest', source: 'winget'),
    PackageItem(id: 'Microsoft.VisualStudioCode', name: 'Visual Studio Code', version: 'Latest', source: 'winget'),
    PackageItem(id: 'Python.Python.3.12', name: 'Python 3.12', version: 'Latest', source: 'winget'),
    PackageItem(id: 'OpenJS.NodeJS.LTS', name: 'Node.js LTS', version: 'Latest', source: 'winget'),
    PackageItem(id: 'OBSProject.OBSStudio', name: 'OBS Studio', version: 'Latest', source: 'winget'),
    PackageItem(id: 'Discord.Discord', name: 'Discord', version: 'Latest', source: 'winget'),
    PackageItem(id: 'Valve.Steam', name: 'Steam', version: 'Latest', source: 'winget'),
    PackageItem(id: 'Spotify.Spotify', name: 'Spotify', version: 'Latest', source: 'winget'),
    PackageItem(id: 'BlenderFoundation.Blender', name: 'Blender', version: 'Latest', source: 'winget'),
  ];

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    _results = List.from(_curatedQuickPackages);
  }

  Future<void> _checkAvailability() async {
    final w = await PackageManagerService.isWingetAvailable();
    final c = await PackageManagerService.isChocoAvailable();
    if (mounted) {
      setState(() {
        _hasWinget = w;
        _hasChoco = c;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = List.from(_curatedQuickPackages);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusLog = 'Pesquisando nos repositórios universais...';
    });

    final List<PackageItem> fetched = [];

    if (_selectedSource == 'all' || _selectedSource == 'winget') {
      final wResults = await PackageManagerService.searchWinget(query);
      fetched.addAll(wResults);
    }

    if (_selectedSource == 'all' || _selectedSource == 'chocolatey') {
      final cResults = await PackageManagerService.searchChoco(query);
      fetched.addAll(cResults);
    }

    if (mounted) {
      setState(() {
        _results = fetched;
        _isLoading = false;
        _statusLog = fetched.isEmpty ? 'Nenhum pacote encontrado para "$query".' : 'Encontrados ${fetched.length} pacotes.';
      });
    }
  }

  Future<void> _install(PackageItem pkg) async {
    setState(() {
      _installing[pkg.id] = true;
      _statusLog = 'Iniciando instalação de ${pkg.name}...';
    });

    final success = await PackageManagerService.installPackage(
      packageId: pkg.id,
      source: pkg.source,
      onStatus: (status) {
        if (mounted) setState(() => _statusLog = status);
      },
    );

    if (mounted) {
      setState(() {
        _installing[pkg.id] = false;
        _statusLog = success ? '✅ ${pkg.name} instalado com sucesso!' : '❌ Falha ao instalar ${pkg.name}.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${pkg.name} instalado com sucesso!' : 'Falha ao instalar ${pkg.name}.'),
          backgroundColor: success ? const Color(0xFF00FFCC) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Os gerenciadores Winget e Chocolatey são exclusivos para Windows.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho e Barra de Pesquisa Estilo UniGetUI
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.source_rounded, color: AppColors.accentCyan, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gerenciadores de Pacotes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Repositórios universais do Windows Package Manager (Winget) e Chocolatey',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Indicadores de Disponibilidade
                  Row(
                    children: [
                      _buildSourceChip(
                        name: 'Winget',
                        icon: Icons.window,
                        isAvailable: _hasWinget,
                        color: AppColors.accentCyan,
                      ),
                      const SizedBox(width: 10),
                      _buildSourceChip(
                        name: 'Chocolatey',
                        icon: Icons.cookie_outlined,
                        isAvailable: _hasChoco,
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campo de Pesquisa em Tempo Real
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: _performSearch,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Pesquise milhares de softwares no Winget e Chocolatey...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.search, color: AppColors.accentCyan),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.accentCyan),
                        onPressed: () => _performSearch(_searchCtrl.text),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtros de Fonte
                  Row(
                    children: [
                      _buildFilterPill('all', 'Todos os Repositórios'),
                      const SizedBox(width: 8),
                      _buildFilterPill('winget', 'Apenas Winget'),
                      const SizedBox(width: 8),
                      _buildFilterPill('chocolatey', 'Apenas Chocolatey'),
                    ],
                  ),
                ],
              ),
            ),

            // Status Banner / Console de Execução
            if (_statusLog != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                      )
                    else
                      const Icon(Icons.terminal_rounded, size: 16, color: AppColors.accentCyan),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusLog!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Lista de Resultados
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
                  : _results.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum pacote encontrado nos repositórios.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pkg = _results[index];
                            final isBusy = _installing[pkg.id] ?? false;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  // Badge de Fonte
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: pkg.source == 'winget'
                                          ? AppColors.accentCyan.withValues(alpha: 0.15)
                                          : Colors.orangeAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      pkg.source == 'winget' ? Icons.window : Icons.cookie_outlined,
                                      color: pkg.source == 'winget' ? AppColors.accentCyan : Colors.orangeAccent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Detalhes do Pacote
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pkg.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              pkg.id,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'monospace',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                                            Text(
                                              pkg.version,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: pkg.source == 'winget' ? AppColors.accentCyan : Colors.orangeAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Botão de Instalação
                                  if (isBusy)
                                    const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentCyan),
                                    )
                                  else
                                    FilledButton.tonal(
                                      onPressed: () => _install(pkg),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.surface,
                                        foregroundColor: AppColors.textPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text('Instalar', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceChip({
    required String name,
    required IconData icon,
    required bool isAvailable,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAvailable ? color.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isAvailable ? color : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$name: ${isAvailable ? "Ativo" : "Não detectado"}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAvailable ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String id, String label) {
    final isSelected = _selectedSource == id;
    return InkWell(
      onTap: () {
        setState(() => _selectedSource = id);
        _performSearch(_searchCtrl.text);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentCyan : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accentCyan : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}