# Project: Comprehensive Home Network Security Monitoring

This guide provides a blueprint for setting up a robust security monitoring solution for your home network using powerful open-source tools. By the end of this project, you will have a system that can detect threats, analyze traffic, and provide deep visibility into what's happening on your network.

---

## 1. Core Components & Architecture

Our setup relies on three key open-source tools working together.

* **pfSense:** This will be your network's primary firewall and router. It's a highly flexible and powerful platform that will replace your consumer-grade router. It will act as the gatekeeper, controlling all traffic entering and leaving your network.

* **Snort:** This is an Intrusion Detection and Prevention System (IDS/IPS). We will run it directly on our pfSense firewall. Its job is to analyze network traffic in real-time, looking for signatures of malicious activity, and then logging alerts.

* **Wazuh (SIEM):** This is our Security Information and Event Management (SIEM) system. Think of it as the central command center. It will collect, parse, and analyze logs from both pfSense and Snort. Its powerful dashboard (built on Kibana) will allow us to visualize the data, identify trends, and receive alerts for critical events.

#### Network Architecture

The data will flow through your network in the following way:

  [Internet]
      |
      |
  [Modem]
      |
      |
+---------------------+ |   pfSense Firewall  | | (with Snort IDS)    | +---------------------+ | | [LAN Switch] | ||             |                    |[Your PCs] [IoT Devices] [Wireless Access Point] ...etc.
* **Log Flow:** pfSense and Snort will generate logs for firewall events and security alerts. These logs will be forwarded over the network to your dedicated Wazuh server for analysis.

---

## 2. Hardware & Software Requirements

### pfSense Box:

* **Hardware:** A dedicated machine with at least **two Network Interface Cards (NICs)** is required—one for WAN (Internet) and one for LAN (your network). An old desktop, a small form-factor PC (like a Qotom or Protectli appliance), or a virtual machine with appropriate network configuration will work.
* **Recommended Specs:** Dual-core CPU, 4GB RAM, 32GB storage.
* **Software:** [pfSense CE (Community Edition) ISO](https://www.pfsense.org/download/).

### Wazuh SIEM Server:

* **Hardware:** This can be a virtual machine on a more powerful computer or a separate physical machine (even a Raspberry Pi 4 with 8GB RAM can work for a small home network).
* **Recommended Specs:** 2-4 CPU cores, 8GB RAM, 100GB storage (for log retention).
* **Software:** [Wazuh OVA (Open Virtualization Appliance)](https://documentation.wazuh.com/current/deployment-options/virtual-machine/virtual-machine.html). This is the easiest way to start, as it's a pre-built virtual machine.

---

## 3. Step-by-Step Implementation Plan

### Part 1: Install and Configure pfSense

1.  **Create Bootable USB:** Download the pfSense ISO and use a tool like Rufus or Balena Etcher to create a bootable USB drive.
2.  **Install pfSense:** Boot your dedicated firewall machine from the USB drive and follow the on-screen installation prompts. The process is straightforward.
3.  **Initial Setup:**
    * The most critical step is assigning the correct network interfaces to **WAN** and **LAN**.
    * Connect the WAN port to your modem and the LAN port to your switch.
    * Access the pfSense WebGUI from a computer on the LAN by navigating to its default IP (usually `192.168.1.1`).
    * Complete the initial setup wizard.

### Part 2: Install and Configure Snort on pfSense

1.  **Install Package:** In the pfSense WebGUI, navigate to `System > Package Manager > Available Packages`. Search for "Snort" and install it.
2.  **Initial Configuration:**
    * Go to `Services > Snort > Global Settings`. Enable rule updates by registering for a free [Snort Oinkcode](https://www.snort.org/users/sign_up) and entering it here.
    * Go to the `Snort Interfaces` tab and add one for your **LAN** interface.
3.  **Configure LAN Interface:**
    * In the LAN interface settings, check **"Send Alerts to System Log"**. This is crucial for sending data to our SIEM.
    * Under `LAN Categories`, start by selecting a few rule sets. The `emerging-threats` rules are a great starting point.
    * **Crucially, leave "Block Offenders" unchecked for now.** We will run Snort in IDS mode (detection only) first to avoid accidentally blocking legitimate traffic.

### Part 3: Install and Configure Wazuh (SIEM)

1.  **Deploy OVA:** Import the downloaded Wazuh OVA into your hypervisor (VirtualBox, VMware, etc.).
2.  **Start VM:** Boot the virtual machine. It will automatically start all the necessary services. Note its IP address.
3.  **Access Web Interface:** From your web browser, navigate to the Wazuh server's IP address. You will be greeted by the login screen. Use the default credentials and change them immediately.

### Part 4: Forwarding Logs from pfSense to Wazuh

1.  **Configure pfSense Syslog:**
    * In the pfSense WebGUI, go to `Status > System Logs > Settings`.
    * Scroll down to **"Remote Logging Options"**.
    * Check **"Enable Remote Logging"**.
    * In the **"Remote log servers"** field, enter the IP address of your Wazuh server.
    * Under **"Remote Syslog Contents"**, check **"Everything"**. This ensures firewall logs, Snort alerts, and other system events are all sent.
2.  **Verify in Wazuh:** After a few minutes, you should see events from pfSense appearing in the Wazuh dashboard (`Modules > Security events`). Wazuh has built-in decoders for pfSense and Snort, so the logs should be parsed and categorized automatically.

---

## 4. Monitoring and Next Steps

* **Explore the Dashboard:** Spend time exploring the Wazuh interface. You can see firewall denies, Snort alerts, and system authentications all in one place.
* **Tune Snort Rules:** You may find that some Snort rules are noisy and trigger false positives. In the Snort settings on pfSense, you can disable specific rules that are causing issues.
* **Enable Blocking (IPS Mode):** Once you are confident that Snort is not generating false positives for your normal traffic, you can go back to the Snort interface settings in pfSense and check **"Block Offenders"** to turn your IDS into an active IPS.
* **Set Up Alerts:** Configure Wazuh to send you email or Slack notifications for high-severity events (e.g., any Snort alert with a priority of 1).
