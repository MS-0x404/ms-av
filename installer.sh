#!/bin/bash
#############################################################
# MS-AV INSTALLER
# Autore: MagicSale!
# Versione: 1.0
# Descrizione: Installer automatico per MS-AV
#############################################################

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variabili globali
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/av-config"
LOG_DIR="/var/log/av-logs"
QUARANTINE_DIR="/quarantena"
DB_DIR="$CONFIG_DIR/db_firme"

# Banner di benvenuto
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║    🛡️  MS-AV INSTALLER v1.0                                  ║"
    echo "║                                                              ║"
    echo "║    Installazione automatica dell'antivirus MS-AV            ║"
    echo "║    Autore: MagicSale!                                       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Funzione per logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERRORE]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Controlla privilegi root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Questo installer deve essere eseguito come root!"
        echo "Utilizzo: sudo $0"
        exit 1
    fi
}

# Rileva distribuzione Linux
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        error "Impossibile rilevare la distribuzione Linux"
        exit 1
    fi
    
    log "Distribuzione rilevata: $PRETTY_NAME"
}

# Installa dipendenze per Ubuntu/Debian
install_deps_debian() {
    log "Aggiornamento repositories APT..."
    apt update > /dev/null 2>&1
    
    log "Installazione dipendenze per Ubuntu/Debian..."
    
    local packages=(
        "clamav"
        "clamav-daemon" 
        "clamav-freshclam"
        "openssl"
        "curl"
        "uuid-runtime"
        "libnotify-bin"
        "mailutils"
        "cron"
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log "$package già installato ✓"
        else
            log "Installazione $package..."
            apt install -y "$package" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                success "$package installato ✓"
            else
                warn "Errore nell'installazione di $package"
            fi
        fi
    done
}

# Installa dipendenze per CentOS/RHEL/Fedora
install_deps_redhat() {
    log "Installazione dipendenze per CentOS/RHEL/Fedora..."
    
    local packages=(
        "clamav"
        "clamav-update"
        "openssl"
        "curl"
        "util-linux"
        "libnotify"
        "mailx"
        "cronie"
    )
    
    # Determina il package manager
    if command -v dnf > /dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum > /dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        error "Package manager non supportato"
        exit 1
    fi
    
    # Abilita EPEL per CentOS/RHEL
    if [[ "$DISTRO" =~ ^(centos|rhel)$ ]]; then
        log "Abilitazione repository EPEL..."
        $PKG_MANAGER install -y epel-release > /dev/null 2>&1
    fi
    
    for package in "${packages[@]}"; do
        log "Installazione $package..."
        $PKG_MANAGER install -y "$package" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            success "$package installato ✓"
        else
            warn "Errore nell'installazione di $package"
        fi
    done
}

install_deps_arch() {
    log "Installazione dipendenze per Arch..."
    pacman -Sy --noconfirm > /dev/null 2>&1

    local packages=(
        "clamav"
        "openssl"
        "curl"
        "util-linux"    # per uuidgen
        "libnotify"
        "mailutils"     # potresti voler usare 'heirloom-mailx' o 'bsd-mailx' se mailutils non è disponibile
        "cronie"
    )

    for package in "${packages[@]}"; do
        if pacman -Q "$package" > /dev/null 2>&1; then
            log "$package già installato ✓"
        else
            log "Installazione $package..."
            pacman -S --noconfirm "$package" > /dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                success "$package installato ✓"
            else
                warn "Errore nell'installazione di $package"
            fi
        fi
    done
    
}
# Installa dipendenze basate sulla distribuzione
install_dependencies() {
    log "Installazione dipendenze del sistema..."
    
    case "$DISTRO" in
        "ubuntu"|"debian")
            install_deps_debian
            ;;
        "centos"|"rhel"|"fedora")
            install_deps_redhat
            ;;
        "arch")
            install_deps_arch
            ;;
        *)
            warn "Distribuzione $DISTRO non testata, procedendo con installazione generica..."
            install_deps_debian
            ;;
    esac
}

# Crea struttura directory
create_directories() {
    log "Creazione struttura directory..."
    
    local directories=(
        "$CONFIG_DIR"
        "$DB_DIR"
        "$LOG_DIR"
        "$QUARANTINE_DIR"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 755 "$dir"
            success "Directory creata: $dir"
        else
            log "Directory esistente: $dir ✓"
        fi
    done
    
    # Permessi speciali per quarantena
    chmod 700 "$QUARANTINE_DIR"
    log "Permessi di sicurezza impostati per quarantena"
}

# Crea file di configurazione
create_config() {
    log "Creazione file di configurazione..."
    
    local config_file="$CONFIG_DIR/av.conf"
    
    # Chiedi username per la configurazione
    read -p "Inserisci username per scansioni automatiche [$(whoami)]: " username
    username=${username:-$(whoami)}
    
    # Chiedi frequenza scansioni
    read -p "Frequenza scansioni automatiche in minuti [60]: " frequency
    frequency=${frequency:-60}
    
    # Chiedi email per report (opzionale)
    read -p "Email per report automatici (opzionale): " email
    
    cat > "$config_file" << EOF
#!/bin/bash
# MS-AV Configuration File
# Generated by installer on $(date)

# Directory di quarantena
DIRECTORY_QUARANTENA="$QUARANTINE_DIR"

# Directory dei log
PATH_LOG="$LOG_DIR"

# Percorsi database firme
PATH_FIRME_MAIN="$DB_DIR/main.hdb"
PATH_FIRME_DAILY="$DB_DIR/daily.cld"
PATH_FIRME_SHA="$DB_DIR/firme_sha256.txt"

# Configurazione scansione automatica
FREQUENZA_SCANSIONE="$frequency"
UTENTE_ABILITATO_AL_DOWNLOAD="$username"

# Estensioni da escludere dalla scansione
ESTENSIONI_DA_ESCLUDERE=(
    "log" "tmp" "cache" "lock" "pid" "sock"
    "swp" "swap" "core" "dump" "bak" "backup"
    "iso" "img" "vmdk" "vdi" "qcow2"
)

# Path da escludere dalla scansione
PATH_DA_ESCLUDERE=(
    "/proc" "/sys" "/dev" "/tmp" "/var/tmp"
    "/run" "/boot" "/media" "/mnt" "/lost+found"
    "/var/lib/docker" "/snap" "/var/cache"
)

# Email per report (lasciare vuoto per disabilitare)
INVIO_MAIL="$email"

EOF
    
    chmod 644 "$config_file"
    success "File di configurazione creato: $config_file"
}

# Installa script principale
install_main_script() {
    log "Installazione script principale MS-AV..."
    
    if [[ -f "ms-av.sh" ]]; then
        cp "ms-av.sh" "$INSTALL_DIR/ms-av"
        chmod +x "$INSTALL_DIR/ms-av"
        success "Script principale installato in $INSTALL_DIR/ms-av"
    else
        error "File ms-av.sh non trovato nella directory corrente"
        exit 1
    fi
}

# Aggiorna database ClamAV
update_clamav_db() {
    log "Aggiornamento database ClamAV..."
    
    # Ferma il servizio se in esecuzione
    systemctl stop clamav-freshclam 2>/dev/null || true
    
    # Configura freshclam
    if [[ -f /etc/clamav/freshclam.conf ]]; then
        # Ubuntu/Debian
        sed -i 's/^Example/#Example/' /etc/clamav/freshclam.conf 2>/dev/null || true
    elif [[ -f /etc/freshclam.conf ]]; then
        # CentOS/RHEL
        sed -i 's/^Example/#Example/' /etc/freshclam.conf 2>/dev/null || true
    fi
    
    # Prima esecuzione di freshclam
    log "Download database firme (può richiedere alcuni minuti)..."
    freshclam --quiet
    
    if [[ $? -eq 0 ]]; then
        success "Database ClamAV aggiornato ✓"
    else
        warn "Errore nell'aggiornamento ClamAV, continuando l'installazione..."
    fi
    
    # Riavvia servizio freshclam
    systemctl enable clamav-freshclam 2>/dev/null || true
    systemctl start clamav-freshclam 2>/dev/null || true
}

# Crea link simbolici
create_symlinks() {
    log "Creazione collegamenti rapidi..."
    
    # Link per comando ms-av
    if [[ ! -L /usr/local/bin/ms-av ]]; then
        ln -sf /usr/bin/ms-av /usr/local/bin/ms-av
        success "Link simbolico creato: /usr/local/bin/ms-av"
    fi
    
    # Aggiunge al PATH se necessario
    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile
        log "PATH aggiornato in /etc/profile"
    fi
}

# Test installazione
test_installation() {
    log "Test dell'installazione..."
    
    local tests_passed=0
    local total_tests=5
    
    # Test 1: Script principale
    if [[ -x "$INSTALL_DIR/ms-av" ]]; then
        success "✓ Script principale installato"
        ((tests_passed++))
    else
        error "✗ Script principale mancante"
    fi
    
    # Test 2: File di configurazione
    if [[ -f "$CONFIG_DIR/av.conf" ]]; then
        success "✓ File di configurazione presente"
        ((tests_passed++))
    else
        error "✗ File di configurazione mancante"
    fi
    
    # Test 3: Directory di quarantena
    if [[ -d "$QUARANTINE_DIR" ]]; then
        success "✓ Directory di quarantena creata"
        ((tests_passed++))
    else
        error "✗ Directory di quarantena mancante"
    fi
    
    # Test 4: ClamAV
    if command -v freshclam > /dev/null 2>&1; then
        success "✓ ClamAV installato"
        ((tests_passed++))
    else
        error "✗ ClamAV non trovato"
    fi
    
    # Test 5: Dipendenze core
    if command -v openssl > /dev/null 2>&1 && command -v curl > /dev/null 2>&1; then
        success "✓ Dipendenze core presenti"
        ((tests_passed++))
    else
        error "✗ Dipendenze core mancanti"
    fi
    
    echo ""
    if [[ $tests_passed -eq $total_tests ]]; then
        success "🎉 Installazione completata con successo! ($tests_passed/$total_tests test passati)"
        return 0
    else
        warn "⚠️ Installazione completata con avvisi ($tests_passed/$total_tests test passati)"
        return 1
    fi
}

# Mostra informazioni post-installazione
show_post_install_info() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    INSTALLAZIONE COMPLETATA                 ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}📚 UTILIZZO:${NC}"
    echo "   Avvia MS-AV:              sudo ms-av"
    echo "   Scansione automatica:     sudo av-auto"
    echo "   Configurazione:           sudo nano $CONFIG_DIR/av.conf"
    echo ""
    echo -e "${GREEN}📁 DIRECTORY IMPORTANTI:${NC}"
    echo "   Configurazione:  $CONFIG_DIR"
    echo "   Log:             $LOG_DIR"
    echo "   Quarantena:      $QUARANTINE_DIR"
    echo "   Database firme:  $DB_DIR"
    echo ""
    echo -e "${GREEN}🔧 COMANDI UTILI:${NC}"
    echo "   Aggiorna firme:           sudo freshclam"
    echo "   Visualizza log:           sudo tail -f $LOG_DIR/*.log"
    echo "   Svuota quarantena:        sudo rm -rf $QUARANTINE_DIR/*"
    echo "   Stato servizi:            sudo systemctl status clamav-freshclam"
    echo ""
    echo -e "${GREEN}📖 DOCUMENTAZIONE:${NC}"
    echo "   README:    https://github.com/username/ms-av/blob/main/README.md"
    echo "   Issues:    https://github.com/username/ms-av/issues"
    echo ""
    echo -e "${YELLOW}⚠️ IMPORTANTE:${NC}"
    echo "   - Esegui sempre MS-AV come root (sudo)"
    echo "   - Il primo aggiornamento delle firme può richiedere tempo"
    echo "   - Controlla periodicamente i log per monitorare il sistema"
    echo ""
    echo -e "${PURPLE}🎓 Progetto sviluppato per Istituto InfoBasic${NC}"
    echo -e "${PURPLE}   Autore: MagicSale! - MS-AV v1.0${NC}"
    echo ""
}

# Funzione di cleanup in caso di errore
cleanup_on_error() {
    warn "Pulizia installazione parziale..."
    rm -f "$INSTALL_DIR/ms-av"
    rm -rf "$CONFIG_DIR"
    rm -f /etc/cron.daily/ms-av-update
    rm -f /etc/logrotate.d/ms-av
    error "Installazione annullata"
    exit 1
}

# Funzione di disinstallazione
uninstall() {
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    MS-AV UNINSTALLER                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    read -p "Sei sicuro di voler disinstallare MS-AV? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Disinstallazione annullata"
        exit 0
    fi
    
    log "Disinstallazione MS-AV in corso..."
    
    # Rimuovi cron jobs
    crontab -l 2>/dev/null | grep -v "av-auto" | crontab - 2>/dev/null || true
    success "Cron jobs rimossi"
    
    # Rimuovi file e directory
    rm -f "$INSTALL_DIR/ms-av"
    rm -f "/usr/bin/av-auto"
    rm -f "/usr/local/bin/ms-av"
    rm -f "/etc/cron.daily/ms-av-update"
    rm -f "/etc/logrotate.d/ms-av"
    
    # Chiedi se rimuovere dati
    read -p "Rimuovere anche log e quarantena? [y/N]: " remove_data
    if [[ "$remove_data" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        rm -rf "$LOG_DIR"  
        rm -rf "$QUARANTINE_DIR"
        success "Dati rimossi"
    else
        log "Dati conservati in $CONFIG_DIR, $LOG_DIR, $QUARANTINE_DIR"
    fi
    
    success "MS-AV disinstallato completamente"
}

# Menu principale installer
main_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}Seleziona un'opzione:${NC}"
        echo ""
        echo "1. 🚀 Installazione Completa"
        echo "2. 🔄 Aggiorna MS-AV"
        echo "3. 🧪 Test Installazione"
        echo "4. 🗑️ Disinstalla MS-AV"
        echo "5. ❌ Esci"
        echo ""
        read -p "Scelta [1-5]: " choice
        
        case $choice in
            1)
                full_install
                break
                ;;
            2)
                update_install
                break
                ;;
            3)
                test_installation
                read -p "Premi INVIO per continuare..."
                ;;
            4)
                uninstall
                break
                ;;
            5)
                log "Installazione annullata dall'utente"
                exit 0
                ;;
            *)
                error "Opzione non valida"
                sleep 1
                ;;
        esac
    done
}

# Installazione completa
full_install() {
    log "Avvio installazione completa MS-AV..."
    
    # Trap per cleanup su errore
    trap cleanup_on_error ERR
    
    detect_distro
    install_dependencies
    create_directories
    create_config
    install_main_script
    update_clamav_db
    create_symlinks
    
    if test_installation; then
        show_post_install_info
    else
        warn "Installazione completata con alcuni problemi"
        echo "Consulta i log per maggiori dettagli"
    fi
    
    # Rimuovi trap
    trap - ERR
}

# Aggiornamento installazione esistente
update_install() {
    log "Aggiornamento MS-AV esistente..."
    
    if [[ ! -f "$INSTALL_DIR/ms-av" ]]; then
        error "MS-AV non sembra essere installato"
        read -p "Procedere con installazione completa? [y/N]: " install_full
        if [[ "$install_full" =~ ^[Yy]$ ]]; then
            full_install
        fi
        return
    fi
    
    # Backup configurazione esistente
    if [[ -f "$CONFIG_DIR/av.conf" ]]; then
        cp "$CONFIG_DIR/av.conf" "$CONFIG_DIR/av.conf.backup"
        log "Backup configurazione creato"
    fi
    
    install_main_script
    update_clamav_db
    
    success "MS-AV aggiornato con successo"
    log "Configurazione precedente salvata in $CONFIG_DIR/av.conf.backup"
}

# Parsing argomenti comando
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install)
                check_root
                full_install
                exit 0
                ;;
            --uninstall)
                check_root
                uninstall
                exit 0
                ;;
            --update)
                check_root
                update_install
                exit 0
                ;;
            --test)
                test_installation
                exit $?
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Opzione sconosciuta: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Mostra help
show_help() {
    echo "MS-AV Installer v1.0"
    echo ""
    echo "Utilizzo: $0 [OPZIONE]"
    echo ""
    echo "Opzioni:"
    echo "  --install     Installazione completa automatica"
    echo "  --update      Aggiorna installazione esistente"  
    echo "  --uninstall   Rimuove MS-AV dal sistema"
    echo "  --test        Testa installazione esistente"
    echo "  --help, -h    Mostra questo help"
    echo ""
    echo "Senza opzioni viene mostrato il menu interattivo"
    echo ""
    echo "Esempi:"
    echo "  sudo $0                 # Menu interattivo"
    echo "  sudo $0 --install       # Installazione automatica"
    echo "  sudo $0 --uninstall     # Disinstallazione"
}

# ==========================================
# MAIN EXECUTION
# ==========================================

# Controlla se in ambiente CI/automatico
if [[ -n "$CI" || -n "$AUTOMATED" ]]; then
    check_root
    full_install
    exit $?
fi

# Se ci sono argomenti, processali
if [[ $# -gt 0 ]]; then
    parse_args "$@"
fi

# Altrimenti mostra menu interattivo
check_root
main_menu
