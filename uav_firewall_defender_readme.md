# UAV Firewall Defender 🛡️🚁

**SHPEHackerz Workshop Project**

This repository contains the code and instructions for the **UAV Firewall Defender** simulation. The project demonstrates core cybersecurity concepts, specifically **Defense-in-Depth**, by walking you through building and protecting a simulated drone's ground control station from scratch using both network-layer and application-layer defenses.

## 📝 Project Overview

In this project, we will build everything from the ground up:
1. Write a vulnerable C-based socket listener acting as a UAV ground station.
2. Write a bash script to simulate a denial-of-service/command injection attack using `netcat`.
3. Create a network-layer firewall script using `iptables` to block malicious IP addresses.
4. Modify our C program to implement application-layer Deep Packet Inspection (DPI) to detect and drop malicious payloads from spoofed, authorized IPs.

## ⚙️ Prerequisites

To build and run this simulation, you will need a Linux environment (local, VM, or cloud-based like GitHub Codespaces) with the following tools installed:
* `gcc` (GNU Compiler Collection)
* `make`
* `nc` (Netcat)
* `iptables` (Requires `sudo` privileges)

---

## 🚀 Step-by-Step Build & Execution Guide

### Step 1: Build the UAV Control Node

First, we need to build the simulated ground control station. This C program listens for flight commands on port `8080`.

**1. Create `uav_node.c`:**
Create a new file named `uav_node.c` and add the following starter code:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080
#define BUFFER_SIZE 1024

int main() {
    int server_fd, client_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE] = {0};

    // Create socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        exit(EXIT_FAILURE);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    // Bind socket to port
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    // Listen for connections
    if (listen(server_fd, 3) < 0) {
        perror("Listen failed");
        exit(EXIT_FAILURE);
    }

    printf("[*] UAV Control Node active.\n");
    printf("[*] Listening for telemetry on port %d...\n\n", PORT);

    // Accept incoming connections
    while(1) {
        if ((client_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
            perror("Accept failed");
            continue;
        }

        int valread = read(client_socket, buffer, BUFFER_SIZE - 1);
        if (valread > 0) {
            buffer[valread] = '\0'; 
            
            // =========================================================
            // WORKSHOP STEP 4 HOOK: DPI Logic goes here later
            // =========================================================
            
            printf("[+] Received Command: %s", buffer);
        }

        memset(buffer, 0, BUFFER_SIZE);
        close(client_socket);
    }
    return 0;
}
```

**2. Create a `Makefile`:**
Create a file exactly named `Makefile` to compile the C code easily:
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -g
TARGET = uav_node

all: $(TARGET)

$(TARGET): uav_node.c
	$(CC) $(CFLAGS) -o $(TARGET) uav_node.c

clean:
	rm -f $(TARGET)
```

**3. Compile and Run:**
```bash
make all
./uav_node
```

### Step 2: Build and Launch the Threat Scenario

Open a second terminal window. We will script an attacker that uses a distinct loopback IP (`127.0.0.2`) to differentiate from our legitimate (`127.0.0.1`) traffic.

**1. Create `attack.sh`:**
```bash
#!/bin/bash
while true; do
  # The -s flag forces traffic to originate from our simulated "Attacker IP"
  echo "DROP_PAYLOAD" | nc -s 127.0.0.2 -w 1 127.0.0.1 8080
  sleep 0.5
done
```

**2. Execute the Attack:**
```bash
chmod +x attack.sh
./attack.sh
```
*Check your first terminal: You will see the `uav_node` overwhelmed with "DROP_PAYLOAD" commands.*

### Step 3: Build the Network Layer Defense (Firewall)

To block the specific attacker IP, we will write a script to apply network-layer filtering using `iptables`.

**1. Create `firewall.sh` in a third terminal window:**
```bash
#!/bin/bash
# Flush existing rules
sudo iptables -F

# Block the simulated external attacker
sudo iptables -A INPUT -s 127.0.0.2 -j DROP

# Allow legitimate local traffic (from 127.0.0.1)
sudo iptables -A INPUT -i lo -j ACCEPT

echo "[+] Network firewall rules applied. Attacker blocked!"
```

**2. Execute the Firewall:**
```bash
chmod +x firewall.sh
./firewall.sh
```
*Result: The attack script will start timing out. Legitimate commands sent manually (`echo "TURN_LEFT" | nc 127.0.0.1 8080`) will still succeed.*

### Step 4: Add Application Layer Defense (Deep Packet Inspection)

If an attacker spoofs the authorized ground station IP (`127.0.0.1`), the network firewall lets the packet through. We must update our C code to inspect the actual payload content.

**1. Update `uav_node.c`:**
Stop the running `uav_node` (`Ctrl+C`). Open `uav_node.c` and replace the "WORKSHOP STEP 4 HOOK" inside the `while(1)` loop with this Deep Packet Inspection logic:

```c
            // Strip trailing newlines from Netcat
            buffer[strcspn(buffer, "\r\n")] = 0; 
            
            // Inspect the payload for known malicious signatures
            if (strstr(buffer, "DROP_PAYLOAD") != NULL || strstr(buffer, "SHUTDOWN") != NULL) {
                printf("[!] FIREWALL ALERT: Malicious payload intercepted!\n");
                printf("    -> Blocked command: '%s'\n", buffer);
                
                char *reject_msg = "ERROR: Command dropped by UAV Firewall.\n";
                write(client_socket, reject_msg, strlen(reject_msg));
            } else {
                printf("[+] Command Authorized: %s\n", buffer);
                
                char *ack_msg = "ACK: Command Executed.\n";
                write(client_socket, ack_msg, strlen(ack_msg));
            }
            printf("--------------------------------------------------\n");
```

**2. Recompile and Test a Spoofed Attack:**
```bash
make clean && make all
./uav_node
```

In another terminal, manually send a spoofed malicious command from the authorized IP:
```bash
echo "DROP_PAYLOAD" | nc 127.0.0.1 8080
```
*Result: The C program successfully detects the malicious string, drops the command, and logs a Firewall Alert to the terminal.*

---

## 🧠 Key Takeaways

* **Network-Layer Limits:** Firewalls (`iptables`) are excellent for blocking known bad actors but are blind to the content of the traffic and vulnerable to IP spoofing.
* **Application-Layer Security:** Inspecting the actual payload ensures that even if an attacker bypasses the perimeter, malicious commands are not executed.
* **Defense-in-Depth:** Combining multiple layers of security provides the most robust protection against cyber threats.

*Developed for SHPE UNT - SHPEHackerz Program*