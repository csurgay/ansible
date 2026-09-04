# Szükséges előismeretek az Ansible bootcamp-hez

"Automatizálni csak azt tudjuk, amit kézzel is meg tudunk csinálni!"

### In this section the following subjects will be covered:

1. Elvárt alapismeretek
1. Linux
1. SSH
1. Hálózati alapismeretek
1. Git
1. Programozás
1. Virtualizáció/konténerizáció
1. Nem feltétlenül szükséges
1. Összefoglalva

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

### Nem feltétlenül szükséges
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
## Összefoglalva

### A Linux alapismeretek a legfontosabbak. 

A résztvevőnek például önállóan meg kell értenie egy ilyen feladatot:

ssh user@server
sudo systemctl status httpd
sudo dnf install httpd
sudo vi /etc/httpd/conf.d/test.conf
