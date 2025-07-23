# 🛡️ MS-AV - Antivirus Linux

<div align="center">

![MS-AV Logo](https://img.shields.io/badge/MS--AV-v1.0-blue?style=for-the-badge&logo=linux)
![Platform](https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge&logo=linux)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

**Un potente antivirus open-source per sistemi Linux con scansione euristica e protezione in tempo reale**

[🚀 Installazione](#-installazione) • [📋 Caratteristiche](#-caratteristiche) • [🔧 Configurazione](#-configurazione) • [📖 Documentazione](#-documentazione)

</div>

---

## 📋 Caratteristiche

### 🔍 **Scansione Avanzata**
- **Scansione Veloce**: Analisi mirata delle directory utente
- **Scansione Completa**: Controllo dell'intero filesystem
- **Rilevamento Euristico**: Identificazione malware basata su pattern comportamentali
- **Multi-Hash Support**: Supporto MD5 e SHA256 per massima accuratezza

### 🛡️ **Protezione**
- **Database Firme Aggiornato**: Integrazione con ClamAV e Abuse.ch
- **Quarantena Sicura**: Isolamento automatico dei file infetti
- **Protezione Real-time**: Monitoraggio automatico programmabile

### 📊 **Reporting & Monitoring**
- **Report Dettagliati**: Log completi in formato testo e JSON
- **Notifiche Desktop**: Avvisi immediati tramite notify-send
- **Statistiche Avanzate**: Metriche di scansione e performance
- **Export Dati**: Esportazione report per analisi esterne

### ⚙️ **Automazione**
- **Cron Integration**: Scansioni automatiche programmabili
- **Auto-Update**: Aggiornamento automatico delle firme malware
- **Configurazione Flessibile**: File di configurazione personalizzabili

---

## 🎯 Screenshot

<div align="center">

### Menu Principale
```
🛡️  MS-AV PROJECT
========================================
    
1. 🔍 Scansione Veloce
2. 🔎 Scansione Completa (File System)
3. 🦠 Visualizza Quarantena                    
4. 🗑️ Rimuovi Minacce            
5. 📄 Visualizza Log
6. 🔄 Aggiorna Firme Malware                      
7. ⚙️ Configurazione Automatica
8. ℹ️ Info              
0. ❌ Esci
```

### Report di Scansione
```
╔══════════════════════════════════════════════╗
║            📋 REPORT SCANSIONE MS-AV          ║
╚══════════════════════════════════════════════╝

📅 Data/Ora: 2024-12-15_14:30:22
👤 Utente: admin
💻 Hostname: server-linux
📂 Path Scansionata: /home/user
🕒 Durata Scansione: 45s
📄 File Scansionati: 1,234
✅ Nessun Malware Rilevato
🛡️ Stato Scansione: PULITO
```

</div>

---

## 🚀 Installazione

### Installazione Automatica (Consigliata)

```bash
# Clona la repository
git clone https://github.com/username/ms-av.git
cd ms-av

# Esegui l'installer automatico
sudo chmod +x installer.sh
sudo ./installer.sh
```

### Installazione Manuale

<details>
<summary>Clicca per espandere i passaggi manuali</summary>

1. **Installa le dipendenze**:
```bash
sudo apt update
sudo apt install clamav clamav-daemon openssl curl uuid-runtime zenity
```

2. **Crea le directory**:
```bash
sudo mkdir -p /etc/av-config/db_firme
sudo mkdir -p /var/log/ms-av
sudo mkdir -p /var/quarantine/ms-av
```

3. **Copia i file**:
```bash
sudo cp ms-av.sh /usr/bin/ms-av
sudo chmod +x /usr/bin/ms-av
sudo cp config/av.conf /etc/av-config/
```

4. **Aggiorna le firme**:
```bash
sudo freshclam
```

</details>

---

## 🔧 Configurazione

### File di Configurazione Principal (`/etc/av-config/av.conf`)

```bash
# Directory di quarantena
DIRECTORY_QUARANTENA="/var/quarantine/ms-av"

# Directory dei log
PATH_LOG="/var/log/ms-av"

# Percorsi database firme
PATH_FIRME_MAIN="/etc/av-config/db_firme/main.hdb"
PATH_FIRME_DAILY="/etc/av-config/db_firme/daily.cld"
PATH_FIRME_SHA="/etc/av-config/db_firme/firme_sha256.txt"

# Configurazione scansione automatica
FREQUENZA_SCANSIONE="60"  # minuti
UTENTE_ABILITATO_AL_DOWNLOAD="user"

# Estensioni da escludere
ESTENSIONI_DA_ESCLUDERE=("log" "tmp" "cache" "lock")

# Path da escludere
PATH_DA_ESCLUDERE=("/proc" "/sys" "/dev" "/tmp")

# Email per report (opzionale)
INVIO_MAIL="admin@domain.com"
```

### Personalizzazione

- **Frequenza Scansioni**: Modifica `FREQUENZA_SCANSIONE` per scansioni più/meno frequenti
- **Directory Escluse**: Aggiungi percorsi a `PATH_DA_ESCLUDERE` per escluderli dalla scansione
- **Estensioni Ignorate**: Personalizza `ESTENSIONI_DA_ESCLUDERE` secondo le tue esigenze

---

## 💻 Utilizzo

### Avvio Interattivo
```bash
sudo ms-av
```

### Comandi da Terminale
```bash
# Scansione automatica (background)
sudo av-auto

# Aggiornamento firme manuale
sudo freshclam
```

### Integrazione Cron
Il sistema configura automaticamente le scansioni periodiche:
```bash
# Visualizza cron jobs attivi
crontab -l | grep av-auto
```

---

## 📊 Output e Report

### Formati di Report

#### Report Testuale
- **Posizione**: `/var/log/ms-av/report-scansione-YYYY-MM-DD_HH:MM:SS.log`
- **Contenuto**: Report completo in formato human-readable

#### Report JSON
- **Posizione**: `/var/log/ms-av/report-scansione-YYYY-MM-DD_HH:MM:SS.json`
- **Utilizzo**: Integrazione con sistemi esterni, dashboard, API

```json
{
  "timestamp": "2024-12-15_14:30:22",
  "utente": "admin",
  "hostname": "server-linux",
  "scan_id": "550e8400-e29b-41d4-a716-446655440000",
  "path_scansionata": "/home/user",
  "durata_scansione": 45,
  "file_scansionati": 1234,
  "malware_trovati": 0,
  "scan_status": "PULITO"
}
```

---

## 🔒 Sicurezza

### Gestione Quarantena
- **Isolamento Sicuro**: I file infetti vengono spostati in directory protetta
- **Eliminazione Sicura**: Utilizzo di `shred` per cancellazione definitiva
- **Backup Automatico**: Log di tutti i file messi in quarantena

### Database Firme
- **Multi-Source**: ClamAV (main.cvd, daily.cld) + Abuse.ch SHA256
- **Auto-Update**: Aggiornamento automatico tramite freshclam
- **Fallback**: Sistema di backup per continuità del servizio

---

## 🛠️ Requisiti di Sistema

### Dipendenze Obbligatorie
- **OS**: Linux (Ubuntu 18.04+, Debian 9+, CentOS 7+)
- **ClamAV**: Per database firme e strumenti di estrazione
- **OpenSSL**: Per calcolo hash MD5/SHA256
- **Curl**: Per download firme aggiuntive
- **UUID Runtime**: Per generazione ID scansione

### Dipendenze Opzionali
- **Zenity**: Per interfaccia grafica (GUI)
- **Mailx**: Per invio report via email
- **Notify-send**: Per notifiche desktop

### Requisiti Hardware
- **RAM**: Minimo 512MB, consigliato 1GB+
- **Storage**: 200MB per installazione + spazio per log e quarantena
- **CPU**: Qualsiasi architettura x86_64 o ARM

---

## 🐛 Troubleshooting

### Problemi Comuni

<details>
<summary><strong>Errore: "Please run as root!"</strong></summary>

**Soluzione**: MS-AV richiede privilegi di root per:
- Accesso a file di sistema
- Creazione directory di quarantena
- Installazione cron jobs

```bash
sudo ms-av  # Esegui sempre con sudo
```
</details>

<details>
<summary><strong>Database firme non trovato</strong></summary>

**Soluzione**: Esegui l'aggiornamento manuale:
```bash
sudo freshclam
sudo ms-av  # Seleziona opzione 6 per aggiornare
```
</details>

<details>
<summary><strong>Scansione molto lenta</strong></summary>

**Soluzione**: Ottimizza escludendo directory non necessarie:
```bash
# Modifica /etc/av-config/av.conf
PATH_DA_ESCLUDERE=("/proc" "/sys" "/dev" "/tmp" "/var/cache")
```
</details>

### Log di Debug
Per problemi avanzati, consulta i log:
```bash
# Log di sistema
tail -f /var/log/ms-av/

# Log ClamAV
tail -f /var/log/clamav/
```

---

## 🤝 Contribuire

Contribuzioni sono benvenute! Per contribuire:

1. **Fork** del progetto
2. **Crea** un branch per la feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** le modifiche (`git commit -m 'Add some AmazingFeature'`)
4. **Push** al branch (`git push origin feature/AmazingFeature`)
5. **Apri** una Pull Request

### Linee Guida
- Segui lo stile di codice esistente
- Aggiungi test per nuove funzionalità
- Aggiorna la documentazione se necessario
- Testa su multiple distribuzioni Linux

---

## 📜 Changelog

### v1.0.0 (2024-12-15)
- **🎉 Release iniziale**
- ✅ Scansione MD5 e SHA256
- ✅ Integrazione ClamAV
- ✅ Sistema di quarantena
- ✅ Report JSON/Testo
- ✅ Scansione automatica
- ✅ Rilevamento euristico

### Roadmap v1.1.0
- 🔄 Interfaccia web dashboard
- 🔄 API REST per integrazione
- 🔄 Supporto database personalizzati
- 🔄 Scansione in tempo reale
- 🔄 Plugin system

---

## 👨‍💻 Autore

**MagicSale!** - *Progetto finale Istituto InfoBasic*

- 📧 Email: [matteosalis04@ik.me](mailto:matteosalis04@ik.me)
- 🌐 GitHub: [@MS-0X404](https://github.com/MS-0x404)
- 💼 LinkedIn: [MagicSale](https://linkedin.com/in/matteosalis04)

---

## 📄 Licenza

Questo progetto è distribuito sotto licenza **MIT**. Vedi il file [LICENSE](LICENSE) per maggiori dettagli.

```
MIT License - Copyright (c) 2024 MagicSale!

Permesso concesso gratuitamente a chiunque ottenga una copia
di questo software per usarlo senza restrizioni...
```

---

## 🙏 Ringraziamenti

- **ClamAV Team** - Per il potente engine antivirus
- **Abuse.ch** - Per il database SHA256 delle minacce
- **Linux Community** - Per il supporto e feedback
- **Istituto InfoBasic** - Per l'opportunità di sviluppo

---

<div align="center">

**⭐ Se MS-AV ti è stato utile, lascia una stella su GitHub! ⭐**

[![GitHub stars](https://img.shields.io/github/stars/MS-0X404/ms-av?style=social)](https://github.com/MS-0X404/ms-av/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/MS-0X404/ms-av?style=social)](https://github.com/MS-0X404/ms-av/network)

---

*Sviluppato con ❤️ per la sicurezza Linux*

</div>
