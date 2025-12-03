# 🛡️ MS-AV - Linux Bash Antivirus (v2.0)

> **High-Performance Parallel Malware Scanner** written in Bash.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge&logo=linux)
![Architecture](https://img.shields.io/badge/Architecture-Multiprocessing-blue?style=for-the-badge)

MS-AV è una suite di sicurezza per sistemi Linux progettata per rilevare minacce tramite analisi di hash (MD5/SHA256) e pattern matching euristico. 

La versione **2.0** introduce un motore di scansione completamente riscritto basato sul **Multiprocessing**, capace di saturare la banda della CPU per massimizzare la velocità di analisi su grandi volumi di file.

---

## 🚀 Cosa c'è di nuovo nella v2.0?

Questa release risolve i colli di bottiglia della versione precedente passando da un'esecuzione sequenziale a una parallela.

### ⚡ Architettura "Parallel Workers"
Il nuovo motore non utilizza cicli lenti. Sfrutta `xargs` per orchestrare processi concorrenti:
- **Multiprocessing Reale:** Utilizza `xargs -P $(nproc)` per lanciare istanze di scansione simultanee su tutti i core disponibili della CPU.
- **I/O-Bound Optimization:** Abbandonato il caricamento dei database in RAM (che causava crash su DB grandi). La v2.0 esegue lo streaming diretto da disco tramite `grep` ottimizzato, garantendo un uso di memoria costante e basso (O(1)).
- **Thread Safety:** Gestione della concorrenza tramite file temporanei per evitare race conditions durante la scrittura dei log JSON.

---

## 📋 Caratteristiche Principali

* **Multi-Core Scanning:** Scansiona N file contemporaneamente (dove N = numero di core CPU).
* **Dual-Engine Hash Check:** Calcolo parallelo di MD5 (ClamAV DB) e SHA256 (Abuse.ch DB) tramite OpenSSL.
* **Gestione Quarantena:** Isolamento automatico dei file infetti.
* **Reporting Avanzato:** Generazione di report in formato JSON per integrazione con SIEM/Dashboard e log testuali per analisi umana.
* **Zero-Dependency (Quasi):** Richiede solo tool standard Linux (`openssl`, `curl`, `xargs`, `grep`).

---

## 🛠️ Installazione e Utilizzo

### Installazione
```bash
git clone [https://github.com/MS-0x404/ms-av.git](https://github.com/MS-0x404/ms-av.git)
cd ms-av
sudo ./installer.sh