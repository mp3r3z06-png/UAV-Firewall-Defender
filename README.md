# UAV-Firewall-Defender
This repository contains the code and instructions for the UAV Firewall Defender simulation. The project demonstrates core cybersecurity concepts, specifically Defense-in-Depth, by walking you through building and protecting a simulated drone's ground control station from scratch using both network-layer and application-layer defenses.

Project Overview
In this project, we will:
Write a vulnerable C-based socket listener acting as a UAV ground station.

Write a bash script to simulate a denial-of-service/command injection attack using netcat.
Create a network-layer firewall script using iptables to block malicious IP addresses.
Modify our C program to implement application-layer Deep Packet Inspection (DPI) to detect and drop malicious payloads from spoofed, authorized IPs.
