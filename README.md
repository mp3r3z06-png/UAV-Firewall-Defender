# UAV-Firewall-Defender
This repository contains the code and instructions for the UAV Firewall Defender simulation. The project demonstrates core cybersecurity concepts, specifically Defense-in-Depth, by walking you through building and protecting a simulated drone's ground control station from scratch using both network-layer and application-layer defenses.

Project Overview

In this project, we will:

Write a vulnerable C-based socket listener acting as a UAV ground station.

Write a bash script to simulate a denial-of-service/command injection attack using netcat.

Create a network-layer firewall script using iptables to block malicious IP addresses.

Modify our C program to implement application-layer Deep Packet Inspection (DPI) to detect and drop malicious payloads from spoofed, authorized IPs.

Prerequisites

To build and run this simulation, you will need a Linux environment with the following tools installed:

gcc (GNU Compiler Collection)

make

nc (Netcat)

iptables (Requires sudo privileges)

Step-by-Step Build & Execution Guide

Step 1: Build the UAV Control Node

First, we need to build the simulated ground control station. This C program listens for flight commands on port 8080.

1. Create uav_node.c:
Create a file called uav_node.c:

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
