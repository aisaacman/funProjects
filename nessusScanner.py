#How to Use the Nessus Parser Tool

#This Python script is designed to be run from your command line. It takes a Nessus scan export file as input and produces a human-readable text report.

#**1. Prerequisites:**

#* **Python 3:** Ensure you have Python 3 installed on your system.
#* **Nessus Export File:** You need a scan results file exported from Tenable Nessus in the `.nessus` (XML) format.

#**2. Save the Script:**

#* Save the code above into a file named `parse_nessus.py`.

#**3. Run the Script:**

#* Open your terminal or command prompt.
#* Navigate to the directory where you saved `parse_nessus.py`.
#* Run the script using the following command structure, replacing the file names with your own:

 #'''bash
 #   python3 parse_nessus.py --file your_scan_results.nessus --output summary_report.txt
 #```

#   * `--file your_scan_results.nessus`: Specifies the input file.
#   * `--output summary_report.txt`: Specifies the name of the report file that will be created.

#**Example `.nessus` File Structure:**

#The script is designed to parse an XML structure similar to the one below. This is a simplified example of what a `.nessus` file contains.


#xml
<?xml version="1.0" ?>
<NessusClientData_v2>
  <Report name="Example Scan" xmlns:cm="http://www.nessus.org/cm">
    <ReportHost name="192.168.1.101">
      <HostProperties>
        <!-- ... host properties ... -->
      </HostProperties>
      <ReportItem port="443" svc_name="https" protocol="tcp" severity="4" pluginID="12345" pluginName="Outdated SSL/TLS Version">
        <cvss_base_score>9.8</cvss_base_score>
        <description>The remote service encrypts traffic using an outdated version of SSL/TLS.</description>
        <synopsis>The remote service is vulnerable to multiple attacks due to an outdated protocol.</synopsis>
        <solution>Enable support for TLS 1.2 and/or 1.3, and disable support for older protocols.</solution>
      </ReportItem>
      <!-- ... more ReportItem blocks ... -->
    </ReportHost>
    <!-- ... more ReportHost blocks ... -->
  </Report>
</NessusClientData_v2>


#After running the script, a `summary_report.txt` file will be created in the same directory, containing a prioritized list of vulnerabilities.
