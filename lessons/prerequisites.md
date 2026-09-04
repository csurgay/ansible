# Ansible bootcamp - Szükséges előismeretek

"Automatizálni csak azt tudjuk, amit kézzel is meg tudunk csinálni!"

### Tartalom

1. Elvárt alapismeretek
1. Nem feltétlenül szükséges
1. Tesztfeladatok

---
## Elvárt alapismeretek

### Linux	
1. Magabiztos alapvető Linux használat: fájlok, könyvtárak, jogosultságok, folyamatok, szolgáltatások kezelése
1. Parancssor	Alapvető shell/parancsok használata (cd, ls, cp, mv, rm, cat, grep, find, ps, systemctl, stb.)
1. Csomagkezelés	Az alapfogalmak ismerete: csomag telepítése, frissítése, eltávolítása (dnf/yum vagy hasonló)
1. Felhasználók, jogosultságok, csoportok, fájlengedélyek, sudo alapvető ismerete
1. Szolgáltatások fogalma és alapvető kezelése, pl. systemctl start/stop/status/enable
1. Konfigurációs fájlok szerkesztése Linuxon (pl. vi/vim, nano)

### SSH	
1. SSH-kapcsolat létrehozása Linux szerverhez
1. SSH-kulcs alapú autentikáció fogalma

### Hálózati alapismeretek
1. IP-cím, hostname, DNS, port
1. TCP/IP alapfogalmak
1. Hogyan éri el a vezérlőgép a távoli szervert

### Git
1. Alapfogalmi szint: repository, commit, branch, clone/pull/push
1. Haladó Git-ismeretek nem szükségesek

### Programozás
1. Logikai gondolkodás
1. Változók, feltételek
1. Ciklusok
1. Egyszerű logikai összefüggések

### Virtualizáció/konténerizáció
1. Image-ek és Konténerek
1. Docker vagy Podman alapszintű használat

---
## Nem feltétlenül szükséges
1. Korábbi Ansible-tapasztalat
1. Python programozási tudás
1. Haladó Linux rendszergazdai tudás
1. Jinja2-ismeret
1. Ansible Role-ok ismerete
1. Ansible Vault használata
1. Ansible Galaxy ismerete
1. Kubernetes ismeret
1. Ansible Automation Platform
1. Mély YAML ismeret

---
## Tesztfeladatok 

A résztvevőknek önállóan meg kell tudni oldani az alábbi feladatokat:

### 1. Bash

Mit csinál az alábbi script részlet?

``` bash
ssh user@server
sudo systemctl status httpd
sudo dnf install httpd
sudo vi /etc/httpd/conf.d/test.conf
```

A) A server-en telepít és elindít egy apache-ot
B) Megkeresi és lemásolja az apache konfigurációját
C) Telepít és konfigurál egy apache-ot
D) Beüzemel és tesztel egy apache-ot

### 2. Linux parancssor

Melyik paranccsal tudod megnézni az aktuális könyvtár tartalmát?

A) pwd
B) ls
C) cd
D) dir

### 3. Könyvtárváltás

Mit csinál az alábbi parancs?

cd /etc/httpd

A) Létrehozza az /etc/httpd könyvtárat
B) Törli az /etc/httpd könyvtárat
C) Az /etc/httpd könyvtárba lép
D) Megmutatja az /etc/httpd tartalmát

### 4. Fájlkeresés

Melyik paranccsal keresnél meg egy httpd.conf nevű fájlt a /etc alatt?

A) grep httpd.conf /etc
B) find /etc -name httpd.conf
C) search /etc httpd.conf
D) locate /etc/httpd.conf

### 5. Jogosultságok

Mit jelent nagyjából ez a jogosultság?

-rwxr-xr--

A) A tulajdonos írhatja, más nem olvashatja
B) A tulajdonos olvashat/írhat/futtathat, a csoport olvashat/futtathat, mások csak olvashatják
C) Mindenki mindent megtehet
D) Senki nem férhet hozzá

### 6. sudo

Mi a célja a sudo használatának?

A) Másik szerverre történő SSH-kapcsolat
B) Egy parancs végrehajtása magasabb jogosultsággal
C) Egy fájl tömörítése
D) Egy Linux szolgáltatás leállítása

### 7. Processzek

Melyik parancs segítségével tudod például megnézni a futó processzeket?

A) ps
B) proc
C) process-list
D) show-process

### 8. Systemd

Mit csinál?

systemctl status sshd

A) Újratelepíti az SSH-t
B) Megmutatja az SSH szolgáltatás állapotát
C) Elindítja az SSH szolgáltatást
D) Letiltja az SSH szolgáltatást

### 9. Csomagkezelés

Fedora/RHEL rendszeren melyik paranccsal telepítenél egy httpd csomagot?

A) apt install httpd
B) rpm --install httpd
C) dnf install httpd
D) pkg install httpd

### 10. SSH

Mit jelent az alábbi parancs?

ssh admin@server1.example.com

A) SSH szervert telepít a server1 gépre
B) SSH-kapcsolatot kezdeményez a server1.example.com gépre admin felhasználóval
C) Létrehoz egy admin nevű felhasználót
D) Letölti az SSH konfigurációját

### 11. SSH-kulcs

Miért használunk SSH public/private key párost?

A) Titkosított fájlok tömörítésére
B) Kulcsalapú autentikációra, jelszó nélküli vagy jelszóval védett bejelentkezéshez
C) DNS-bejegyzések létrehozására
D) Linux jogosultságok beállítására

### 12. Hálózat

Egy szerver IP-címe:

192.168.10.25

A kliensről működik a ping, de az alábbi nem:

ssh user@192.168.10.25

Mi lehet az egyik legvalószínűbb ok?

A) A szerveren nincs processzor
B) A 22-es TCP port nem érhető el, vagy az SSH szolgáltatás nem működik
C) A ping mindig bizonyítja, hogy az SSH működik
D) Az IP-cím biztosan hibás

### 13. Portok

Melyik portot használja alapértelmezés szerint az SSH?

A) 21
B) 22
C) 80
D) 443

### 14. YAML

Mi a probléma az alábbi YAML-lal?

name: webserver
packages:
 - httpd
 - vim
  - git

A) A YAML nem támogat listákat
B) A git behúzása hibás
C) A name nem lehet string
D) Semmi, ez teljesen helyes

### 15. YAML

Mit reprezentál az alábbi YAML?

server:
  hostname: web01
  port: 8080

A) Egy változót és két egymástól független listát
B) Egy server nevű struktúrát, benne hostname és port értékekkel
C) Két Linux parancsot
D) Egy JSON-fájlt

### 16. Logikai gondolkodás

Mit jelent programozási szempontból az alábbi?

IF operating_system == "RedHat"
    install httpd
ELSE
    install apache2

A) Mindkét csomagot telepíti
B) Véletlenszerűen választ
C) A feltétel alapján más műveletet hajt végre
D) Mindig az apache2 csomagot telepíti

### 17. Git

Mit csinál nagyjából?

git clone https://example.com/project.git

A) Törli a Git repositoryt
B) Lemásolja/klónozza a repository tartalmát egy helyi könyvtárba
C) Commitot készít
D) Feltölti a helyi változásokat a szerverre

### 18. Git commit

Mi a szerepe a git commit parancsnak?

A) A változások egy verziójának rögzítése a helyi repository történetében
B) A repository törlése
C) A távoli repository letöltése
D) Linux csomag telepítése

### 19. Konfiguráció

Van egy Linux szerver, amelyen egy webalkalmazás konfigurációja itt található:

/etc/myapp/config.conf

A konfiguráció módosítása után szeretnéd, hogy az alkalmazás az új beállításokat használja.

Melyik két lépés lehet szükséges?

A) A konfiguráció módosítása és az alkalmazás újraindítása/reloadja
B) A gép újratelepítése
C) A Git repository törlése
D) A DNS szerver újraindítása

### 20. Alapvető Ansible-ismeret

Az alábbiak közül melyik írja le legjobban az Ansible működését?

A) Egy kizárólag Linux kernel fejlesztésére szolgáló program
B) Automatizációs eszköz, amellyel többek között távoli rendszerek konfigurációja és alkalmazások telepítése automatizálható
C) Egy adatbázis-kezelő rendszer
D) Egy hálózati protokoll

