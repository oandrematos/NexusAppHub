/* ==========================================================================
   NEXUS APP HUB — CLIENT APPLICATION ENGINE (JS)
   Ecosistema Antigravity // 2026
   ========================================================================== */

const APP_VERSION = "0.2.0";

const State = {
    catalog: null,
    installedMap: {},
    currentPlatform: "all",
    currentCategory: "all",
    searchQuery: "",
    viewMode: "grid",
    selectedApp: null,
    isKiosk: false,
    heroAppIndex: 0,
    heroRotationTimer: null,
    clusterNodes: {
        s1: { ip: "192.168.196.101", online: true, ping: 2 },
        s2: { ip: "192.168.196.102", online: true, ping: 4 },
        adb: { ip: "192.168.0.203", online: true }
    }
};

// Fallback Catalog Data (Loaded in case offline / initial boot)
const FALLBACK_CATALOG = {
    "store_name": "Nexus App Hub",
    "developer": "André (Antigravity)",
    "version": "v0.2.0",
    "base_url": "http://192.168.196.101/installers/",
    "apps": []
};

// ================= INITIALIZATION =================
document.addEventListener("DOMContentLoaded", async () => {
    setupEventListeners();
    setupShortcuts();
    await loadCatalogAndStatus();
    checkOtaUpdates(false);
    startHeroRotation();
    startTelemetryHeartbeat();
});

// ================= DATA LOADING =================
async function loadCatalogAndStatus() {
    try {
        if (window.pywebview && window.pywebview.api) {
            const data = await window.pywebview.api.get_catalog();
            if (data && data.apps) {
                State.catalog = data;
            }
        }
    } catch (e) {
        console.warn("PyWebView API não disponível, carregando via fetch local/cluster:", e);
    }

    if (!State.catalog) {
        try {
            const res = await fetch("../software_catalog.json");
            State.catalog = await res.json();
        } catch (e) {
            console.error("Falha ao carregar catálogo:", e);
            State.catalog = FALLBACK_CATALOG;
        }
    }

    // Carregar detecção de apps instalados no PC
    if (window.pywebview && window.pywebview.api) {
        try {
            State.installedMap = await window.pywebview.api.detect_installed_apps(State.catalog);
        } catch (e) {
            console.warn("Erro ao detectar apps instalados:", e);
        }
    }

    renderCategoryPills();
    updatePlatformCounts();
    renderHeroSpotlight();
    renderAppCards();
}

// ================= HERO SPOTLIGHT =================
function getFeaturedApps() {
    if (!State.catalog || !State.catalog.apps) return [];
    return State.catalog.apps.filter(app => app.featured || app.badge);
}

function renderHeroSpotlight() {
    const featured = getFeaturedApps();
    if (!featured.length) return;
    
    const app = featured[State.heroAppIndex % featured.length];
    if (!app) return;

    document.getElementById("heroBadge").textContent = "★ " + (app.badge || "DESTAQUE");
    document.getElementById("heroPlatformBadge").textContent = (app.platform === "windows" ? "🪟 WINDOWS" : (app.platform === "android" ? "🤖 ANDROID" : "🐧 LINUX"));
    document.getElementById("heroVersionBadge").textContent = app.version || "v1.0.0";
    document.getElementById("heroTitle").textContent = app.title || app.name;
    document.getElementById("heroDesc").textContent = app.description || "";
    document.getElementById("heroArtIcon").textContent = app.icon || "🚀";

    const status = State.installedMap[app.id] || { status: "not_installed" };
    const primaryBtn = document.getElementById("heroPrimaryBtn");
    
    if (status.status === "installed") {
        primaryBtn.innerHTML = '<span class="btn-icon">▶️</span><span class="btn-text">ABRIR AGORA</span>';
        primaryBtn.onclick = () => launchApp(app.id);
    } else if (status.status === "outdated") {
        primaryBtn.innerHTML = '<span class="btn-icon">⚡</span><span class="btn-text">ATUALIZAR</span>';
        primaryBtn.onclick = () => downloadAndInstall(app.id);
    } else {
        primaryBtn.innerHTML = '<span class="btn-icon">⬇️</span><span class="btn-text">INSTALAR</span>';
        primaryBtn.onclick = () => downloadAndInstall(app.id);
    }

    document.getElementById("heroDetailsBtn").onclick = () => showDetailsModal(app.id);
}

function startHeroRotation() {
    if (State.heroRotationTimer) clearInterval(State.heroRotationTimer);
    State.heroRotationTimer = setInterval(() => {
        const featured = getFeaturedApps();
        if (featured.length > 1) {
            State.heroAppIndex++;
            renderHeroSpotlight();
        }
    }, 10000);
}

// ================= CATEGORIES & COUNTS =================
function renderCategoryPills() {
    const row = document.getElementById("categoriesPillsRow");
    if (!row || !State.catalog) return;

    const categories = State.catalog.categories || [
        "Comunicação", "Jogos & Arcade", "Jogos & Emulação", 
        "Produtividade & Gestão", "Ferramentas & Sistema", "IA & Assistentes"
    ];

    let html = `<button class="category-pill ${State.currentCategory === 'all' ? 'active' : ''}" data-category="all">Todas as Categorias</button>`;
    
    categories.forEach(cat => {
        const active = State.currentCategory === cat ? "active" : "";
        html += `<button class="category-pill ${active}" data-category="${cat}">${cat}</button>`;
    });

    row.innerHTML = html;

    row.querySelectorAll(".category-pill").forEach(btn => {
        btn.addEventListener("click", () => {
            row.querySelectorAll(".category-pill").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            State.currentCategory = btn.dataset.category;
            renderAppCards();
        });
    });
}

function updatePlatformCounts() {
    if (!State.catalog || !State.catalog.apps) return;
    const apps = State.catalog.apps;
    
    document.getElementById("countAll").textContent = apps.length;
    document.getElementById("countWindows").textContent = apps.filter(a => a.platform === "windows" || (a.platforms_supported && a.platforms_supported.includes("windows"))).length;
    document.getElementById("countAndroid").textContent = apps.filter(a => a.platform === "android" || (a.platforms_supported && a.platforms_supported.includes("android"))).length;
    document.getElementById("countLinux").textContent = apps.filter(a => a.platform === "linux" || (a.platforms_supported && a.platforms_supported.includes("linux"))).length;
}

// ================= RENDER APP CARDS =================
function renderAppCards() {
    const grid = document.getElementById("appsGrid");
    const emptyState = document.getElementById("emptyState");
    if (!grid || !State.catalog) return;

    let filtered = State.catalog.apps || [];

    // Filter by platform
    if (State.currentPlatform !== "all") {
        filtered = filtered.filter(app => {
            if (app.platform === State.currentPlatform) return true;
            if (app.platforms_supported && app.platforms_supported.includes(State.currentPlatform)) return true;
            return false;
        });
    }

    // Filter by category
    if (State.currentCategory !== "all") {
        filtered = filtered.filter(app => app.category === State.currentCategory);
    }

    // Filter by search
    if (State.searchQuery.trim() !== "") {
        const query = State.searchQuery.toLowerCase();
        filtered = filtered.filter(app => 
            (app.name && app.name.toLowerCase().includes(query)) ||
            (app.title && app.title.toLowerCase().includes(query)) ||
            (app.description && app.description.toLowerCase().includes(query)) ||
            (app.category && app.category.toLowerCase().includes(query))
        );
    }

    document.getElementById("resultsCountTag").textContent = `${filtered.length} ${filtered.length === 1 ? 'item' : 'itens'}`;

    if (filtered.length === 0) {
        grid.innerHTML = "";
        emptyState.style.display = "flex";
        return;
    }

    emptyState.style.display = "none";

    let html = "";
    filtered.forEach(app => {
        const statusInfo = State.installedMap[app.id] || { status: "not_installed" };
        const isWindows = app.platform === "windows";
        const isAndroid = app.platform === "android";
        
        let statusBadgeHtml = "";
        let primaryActionBtn = "";

        if (isWindows) {
            if (statusInfo.status === "installed") {
                statusBadgeHtml = `<span class="install-status-pill installed">● Instalado (${statusInfo.installed_version || app.version})</span>`;
                primaryActionBtn = `<button class="btn-cyber-primary btn-sm" onclick="launchApp('${app.id}')">▶️ Abrir</button>`;
            } else if (statusInfo.status === "outdated") {
                statusBadgeHtml = `<span class="install-status-pill outdated">⚡ Atualização (${statusInfo.installed_version} ➔ ${app.version})</span>`;
                primaryActionBtn = `<button class="btn-cyber-primary btn-sm pulse-glow" onclick="downloadAndInstall('${app.id}')">⚡ Atualizar</button>`;
            } else {
                statusBadgeHtml = `<span class="install-status-pill not-installed">○ Não instalado</span>`;
                primaryActionBtn = `<button class="btn-cyber-primary btn-sm" onclick="downloadAndInstall('${app.id}')">⬇️ Instalar</button>`;
            }
        } else if (isAndroid) {
            statusBadgeHtml = `<span class="install-status-pill not-installed">🤖 Pacote APK</span>`;
            primaryActionBtn = `
                <button class="btn-cyber-primary btn-sm" onclick="downloadAndInstall('${app.id}')">📥 Baixar APK</button>
                <button class="btn-cyber-secondary btn-sm" title="Instalar no Celular via Wi-Fi ADB" onclick="installViaAdb('${app.id}')">📲 ADB</button>
            `;
        } else {
            statusBadgeHtml = `<span class="install-status-pill not-installed">🐧 Linux Package</span>`;
            primaryActionBtn = `<button class="btn-cyber-secondary btn-sm" onclick="showDetailsModal('${app.id}')">🐧 Deploy S1/S2</button>`;
        }

        const platformIcon = isWindows ? "🪟" : (isAndroid ? "🤖" : "🐧");

        html += `
            <div class="app-card" data-app-id="${app.id}">
                <div>
                    <div class="card-top">
                        <div class="card-icon-box">
                            <span class="card-icon">${app.icon || '📦'}</span>
                        </div>
                        <div class="card-header-info">
                            <div class="card-title-row">
                                <h3 class="card-title" title="${app.title || app.name}">${app.name}</h3>
                                <span class="card-platform-icon">${platformIcon}</span>
                            </div>
                            <div class="card-meta-row">
                                <span class="badge-tag version">${app.version}</span>
                                <span class="badge-tag category">${app.category}</span>
                                <span class="badge-tag size">${app.size_mb} MB</span>
                            </div>
                        </div>
                    </div>
                    <p class="card-desc">${app.description || ''}</p>
                </div>

                <div class="card-bottom">
                    ${statusBadgeHtml}
                    <div class="card-actions-group">
                        <button class="btn-cyber-ghost btn-sm" title="Ver Detalhes do Aplicativo" onclick="showDetailsModal('${app.id}')">ℹ️</button>
                        <button class="btn-cyber-ghost btn-sm" title="Instalação Remota P2P em outras máquinas" onclick="openP2pDeployModal('${app.id}')">🚀</button>
                        ${primaryActionBtn}
                    </div>
                </div>
            </div>
        `;
    });

    grid.innerHTML = html;
}

// ================= APP ACTIONS (LAUNCH / INSTALL / ADB) =================
async function launchApp(appId) {
    showToast("Iniciando aplicativo...", "info");
    if (window.pywebview && window.pywebview.api) {
        try {
            const res = await window.pywebview.api.launch_app(appId);
            if (res && res.success) {
                showToast(`🚀 ${res.message || 'Aplicativo aberto com sucesso!'}`, "success");
            } else {
                showToast(`Falha ao abrir: ${res.error || 'Erro desconhecido'}`, "error");
            }
        } catch (e) {
            showToast(`Erro na execução: ${e.message}`, "error");
        }
    } else {
        showToast("Launcher ativo no modo simulador Desktop.", "info");
    }
}

async function downloadAndInstall(appId) {
    const app = State.catalog.apps.find(a => a.id === appId);
    if (!app) return;

    showDownloadDrawer(app.name);

    if (window.NexusBridge && window.NexusBridge.downloadAndInstallApk) {
        // Modo Android Nativo
        const apkUrl = `http://192.168.196.101/installers/${app.filename}`;
        window.NexusBridge.downloadAndInstallApk(apkUrl);
        return;
    }

    if (window.pywebview && window.pywebview.api) {
        try {
            const res = await window.pywebview.api.download_and_install_app(appId);
            if (res && res.success) {
                showToast(`✅ ${app.name} instalado/executado com sucesso!`, "success");
                // Atualizar estado
                State.installedMap = await window.pywebview.api.detect_installed_apps(State.catalog);
                renderAppCards();
                renderHeroSpotlight();
            } else {
                showToast(`Erro na instalação: ${res.error || 'Falha'}`, "error");
            }
        } catch (e) {
            showToast(`Erro no download: ${e.message}`, "error");
        } finally {
            hideDownloadDrawer();
        }
    } else {
        // Fallback Web Browser: Abrir link de download direto do cluster
        window.open(`http://192.168.196.101/installers/${app.filename}`, "_blank");
        setTimeout(hideDownloadDrawer, 2000);
    }
}

async function installViaAdb(appId) {
    const app = State.catalog.apps.find(a => a.id === appId);
    if (!app) return;

    showToast(`📱 Enviando ${app.name} para o celular via ADB Wireless...`, "info");
    if (window.pywebview && window.pywebview.api) {
        try {
            const res = await window.pywebview.api.install_apk_adb(app.filename, "192.168.0.203");
            if (res && res.success) {
                showToast(`✅ ${res.message}`, "success");
            } else {
                showToast(`Erro no envio ADB: ${res.error}`, "error");
            }
        } catch (e) {
            showToast(`Erro ADB: ${e.message}`, "error");
        }
    } else {
        showToast("ADB requer execução no Desktop Nexus App Hub.", "info");
    }
}

// ================= OTA AUTO-UPDATE (SELF-UPDATE) =================
async function checkOtaUpdates(isManual = false) {
    try {
        let versionData = null;
        if (window.pywebview && window.pywebview.api) {
            versionData = await window.pywebview.api.check_ota_update();
        } else {
            const res = await fetch("http://192.168.196.101/installers/nexus_version.json");
            versionData = await res.json();
        }

        if (versionData && versionData.version) {
            const remoteVer = versionData.version.replace("v", "");
            const currentVer = APP_VERSION.replace("v", "");

            if (isVersionNewer(remoteVer, currentVer)) {
                showOtaBanner(versionData);
                if (isManual) showToast(`🚀 Nova versão v${remoteVer} disponível!`, "info");
            } else if (isManual) {
                showToast("Nexus App Hub já está na versão mais recente (v0.2.0)!", "success");
            }
        }
    } catch (e) {
        if (isManual) showToast("Não foi possível verificar atualizações no momento.", "error");
    }
}

function isVersionNewer(remote, current) {
    const rParts = remote.split(".").map(Number);
    const cParts = current.split(".").map(Number);
    for (let i = 0; i < Math.max(rParts.length, cParts.length); i++) {
        const r = rParts[i] || 0;
        const c = cParts[i] || 0;
        if (r > c) return true;
        if (r < c) return false;
    }
    return false;
}

function showOtaBanner(versionData) {
    const banner = document.getElementById("otaBanner");
    document.getElementById("otaNewVersion").textContent = "v" + versionData.version;
    if (versionData.changelog && versionData.changelog.length > 0) {
        document.getElementById("otaChangelogBrief").textContent = versionData.changelog[0];
    }
    banner.style.display = "flex";

    document.getElementById("otaUpdateNowBtn").onclick = async () => {
        showToast("🚀 Baixando atualização do Nexus App Hub...", "info");
        if (window.pywebview && window.pywebview.api) {
            await window.pywebview.api.perform_ota_update();
        } else {
            window.location.href = versionData.windows.installer_url;
        }
    };

    document.getElementById("otaDismissBtn").onclick = () => {
        banner.style.display = "none";
    };
}

// ================= DOWNLOAD DRAWER & PROGRESS =================
function showDownloadDrawer(appName) {
    const drawer = document.getElementById("downloadDrawer");
    document.getElementById("downloadAppName").textContent = `Baixando ${appName}...`;
    document.getElementById("downloadPercentage").textContent = "0%";
    document.getElementById("downloadProgressBar").style.width = "0%";
    document.getElementById("downloadStatusMsg").textContent = "Iniciando transferência via ZeroTier...";
    drawer.style.display = "block";
}

function hideDownloadDrawer() {
    const drawer = document.getElementById("downloadDrawer");
    setTimeout(() => {
        drawer.style.display = "none";
    }, 1200);
}

// Global Callback from Python / Android Bridge
window.__onDownloadProgress = function (data) {
    const drawer = document.getElementById("downloadDrawer");
    if (!drawer) return;
    drawer.style.display = "block";

    const percent = Math.min(100, Math.max(0, data.percent || 0));
    document.getElementById("downloadPercentage").textContent = `${percent}%`;
    document.getElementById("downloadProgressBar").style.width = `${percent}%`;
    
    if (data.message) {
        document.getElementById("downloadStatusMsg").textContent = data.message;
    }
    if (data.speed) {
        document.getElementById("downloadSpeed").textContent = data.speed;
    }

    if (percent >= 100) {
        document.getElementById("downloadStatusMsg").textContent = "Download concluído! Executando instalação...";
        hideDownloadDrawer();
    }
};

window.__nativeUpdateProgress = function (data) {
    window.__onDownloadProgress(data);
};

// ================= MODALS & POPUPS =================
function showDetailsModal(appId) {
    const app = State.catalog.apps.find(a => a.id === appId);
    if (!app) return;

    State.selectedApp = app;

    document.getElementById("modalAppIcon").textContent = app.icon || "🚀";
    document.getElementById("modalAppTitle").textContent = app.title || app.name;
    document.getElementById("modalAppSubtitle").textContent = app.category + " • " + (app.developer || "André (Antigravity)");
    document.getElementById("modalPlatformBadge").textContent = (app.platform === "windows" ? "🪟 WINDOWS" : (app.platform === "android" ? "🤖 ANDROID" : "🐧 LINUX"));
    document.getElementById("modalCategoryBadge").textContent = app.category;
    document.getElementById("modalVersionBadge").textContent = app.version;
    document.getElementById("modalAppDescription").textContent = app.description || "";
    document.getElementById("modalFileSize").textContent = `${app.size_mb} MB`;
    document.getElementById("modalFileName").textContent = app.filename || "--";
    document.getElementById("modalExecName").textContent = app.executable || "--";

    const status = State.installedMap[app.id] || { status: "not_installed" };
    document.getElementById("modalInstallStatus").textContent = status.status === "installed" ? `🟢 Instalado (${status.installed_version})` : (status.status === "outdated" ? `⚡ Desatualizado` : "○ Não instalado");

    // Target Nodes
    const targetNodesRow = document.getElementById("modalTargetNodes");
    const targets = (State.catalog.platforms[app.platform] && State.catalog.platforms[app.platform].target_nodes) || ["ANDRE-PC", "RECEPCAO", "MIGUEL-PC"];
    targetNodesRow.innerHTML = targets.map(node => `<span class="node-tag">🖥️ ${node}</span>`).join("");

    // Modal Actions
    const primaryActionsBox = document.getElementById("modalPrimaryActions");
    if (app.platform === "windows") {
        if (status.status === "installed") {
            primaryActionsBox.innerHTML = `
                <button class="btn-cyber-secondary" onclick="downloadAndInstall('${app.id}')">Reinstalar</button>
                <button class="btn-cyber-primary" onclick="launchApp('${app.id}')">▶️ Abrir Agora</button>
            `;
        } else {
            primaryActionsBox.innerHTML = `<button class="btn-cyber-primary pulse-glow" onclick="downloadAndInstall('${app.id}')">⬇️ Instalar Agora</button>`;
        }
    } else if (app.platform === "android") {
        primaryActionsBox.innerHTML = `
            <button class="btn-cyber-secondary" onclick="installViaAdb('${app.id}')">📲 Enviar ADB</button>
            <button class="btn-cyber-primary" onclick="downloadAndInstall('${app.id}')">📥 Baixar APK</button>
        `;
    }

    document.getElementById("modalP2pDeployBtn").onclick = () => {
        closeAllModals();
        openP2pDeployModal(app.id);
    };

    document.getElementById("detailsModalBackdrop").style.display = "flex";
}

function openP2pDeployModal(appId) {
    const app = State.catalog.apps.find(a => a.id === appId);
    if (!app) return;
    State.selectedApp = app;

    document.getElementById("p2pAppSelected").textContent = `${app.name} (${app.filename})`;
    document.getElementById("p2pLogTerminal").textContent = "Aguardando disparo de deploy silencioso...";
    document.getElementById("p2pModalBackdrop").style.display = "flex";

    document.getElementById("p2pExecuteBtn").onclick = async () => {
        const select = document.getElementById("p2pTargetNodeSelect");
        const [nodeName, nodeIp, nodeUser, nodePass] = select.value.split("|");
        const term = document.getElementById("p2pLogTerminal");

        term.textContent = `[${new Date().toLocaleTimeString()}] Conectando a ${nodeName} (${nodeIp}) via WinRM...
`;
        term.textContent += `[${new Date().toLocaleTimeString()}] Enviando comando de download silencioso de ${app.filename}...
`;

        if (window.pywebview && window.pywebview.api) {
            try {
                const res = await window.pywebview.api.deploy_remote_winrm(app.id, nodeIp, nodeUser, nodePass);
                term.textContent += `[${new Date().toLocaleTimeString()}] Resposta do nó:
${res.log || res.message}
`;
                if (res.success) {
                    showToast(`🚀 Deploy em ${nodeName} disparado com sucesso!`, "success");
                }
            } catch (e) {
                term.textContent += `[ERRO] Falha no WinRM: ${e.message}
`;
            }
        } else {
            term.textContent += `[SIMULADOR] PowerShell Invoke-Command disparado para ${nodeIp}!
`;
            showToast(`🚀 Deploy simulado para ${nodeName}`, "info");
        }
    };
}

function closeAllModals() {
    document.querySelectorAll(".modal-backdrop").forEach(m => m.style.display = "none");
}

// ================= TELEMETRY & HEARTBEAT =================
function startTelemetryHeartbeat() {
    setInterval(async () => {
        if (window.pywebview && window.pywebview.api) {
            try {
                const p1 = await window.pywebview.api.ping_node("192.168.196.101");
                document.getElementById("pingS1").textContent = p1 >= 0 ? `${p1} ms` : "off";
                const p2 = await window.pywebview.api.ping_node("192.168.196.102");
                document.getElementById("pingS2").textContent = p2 >= 0 ? `${p2} ms` : "off";
            } catch (e) {}
        } else {
            document.getElementById("pingS1").textContent = `${Math.floor(Math.random() * 3) + 2} ms`;
            document.getElementById("pingS2").textContent = `${Math.floor(Math.random() * 4) + 3} ms`;
        }
    }, 8000);
}

// ================= TOAST NOTIFICATIONS =================
function showToast(text, type = "info") {
    const container = document.getElementById("toastContainer");
    if (!container) return;

    const toast = document.createElement("div");
    toast.className = `toast ${type}`;
    const icon = type === "success" ? "✅" : (type === "error" ? "❌" : "ℹ️");

    toast.innerHTML = `
        <span class="toast-icon">${icon}</span>
        <span class="toast-text">${text}</span>
    `;

    container.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = "0";
        toast.style.transform = "translateX(50px)";
        toast.style.transition = "0.3s ease";
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// ================= EVENT LISTENERS & SHORTCUTS =================
function setupEventListeners() {
    // Platform tabs
    document.querySelectorAll(".platform-tab").forEach(tab => {
        tab.addEventListener("click", () => {
            document.querySelectorAll(".platform-tab").forEach(t => t.classList.remove("active"));
            tab.classList.add("active");
            State.currentPlatform = tab.dataset.platform;
            renderAppCards();
        });
    });

    // Search Input
    const searchInput = document.getElementById("searchInput");
    const clearBtn = document.getElementById("searchClearBtn");

    searchInput.addEventListener("input", (e) => {
        State.searchQuery = e.target.value;
        clearBtn.style.display = State.searchQuery ? "block" : "none";
        renderAppCards();
    });

    clearBtn.addEventListener("click", () => {
        searchInput.value = "";
        State.searchQuery = "";
        clearBtn.style.display = "none";
        renderAppCards();
    });

    // Refresh Catalog Button
    document.getElementById("refreshCatalogBtn").addEventListener("click", async () => {
        showToast("Recarregando catálogo e status...", "info");
        await loadCatalogAndStatus();
        showToast("Catálogo atualizado com sucesso!", "success");
    });

    // Kiosk Mode Toggle
    document.getElementById("kioskToggleBtn").addEventListener("click", toggleKioskMode);

    // Settings Modal
    document.getElementById("settingsBtn").addEventListener("click", () => {
        document.getElementById("settingsModalBackdrop").style.display = "flex";
    });

    document.getElementById("manualCheckOtaBtn").addEventListener("click", () => {
        checkOtaUpdates(true);
    });

    document.getElementById("settingsSaveBtn").addEventListener("click", closeAllModals);

    // Modal Close buttons
    document.getElementById("detailsModalCloseBtn").addEventListener("click", closeAllModals);
    document.getElementById("p2pModalCloseBtn").addEventListener("click", closeAllModals);
    document.getElementById("p2pCancelBtn").addEventListener("click", closeAllModals);
    document.getElementById("settingsModalCloseBtn").addEventListener("click", closeAllModals);

    // Clear filters empty state
    document.getElementById("clearFiltersBtn").addEventListener("click", () => {
        State.searchQuery = "";
        searchInput.value = "";
        clearBtn.style.display = "none";
        State.currentPlatform = "all";
        State.currentCategory = "all";
        document.querySelectorAll(".platform-tab").forEach(t => t.classList.remove("active"));
        document.querySelector(".platform-tab[data-platform='all']").classList.add("active");
        renderCategoryPills();
        renderAppCards();
    });
}

function toggleKioskMode() {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(err => {
            console.warn("Fullscreen request error:", err);
        });
        State.isKiosk = true;
        showToast("Modo Arcade / Kiosk ativado (F11 para sair)", "info");
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        }
        State.isKiosk = false;
    }
}

function setupShortcuts() {
    window.addEventListener("keydown", (e) => {
        if (e.key === "F11") {
            e.preventDefault();
            toggleKioskMode();
        } else if (e.key === "Escape") {
            closeAllModals();
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "f") {
            e.preventDefault();
            const searchInput = document.getElementById("searchInput");
            searchInput.focus();
            searchInput.select();
        } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "r") {
            e.preventDefault();
            loadCatalogAndStatus();
        }
    });
}
