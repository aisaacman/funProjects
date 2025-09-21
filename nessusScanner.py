import xml.etree.ElementTree as ET
import csv

def parse_nessus_report(file_path):
    """
    Parses a Nessus XML report and extracts vulnerability data.
    
    Args:
        file_path (str): The path to the .nessus file.
        
    Returns:
        list: A list of dictionaries, where each dictionary represents a vulnerability finding.
    """
    findings = []
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        # Iterate through each <ReportHost> and its children
        for report_host in root.findall('.//ReportHost'):
            host_ip = report_host.attrib.get('name')
            
            # Iterate through each <ReportItem> for the host
            for report_item in report_host.findall('ReportItem'):
                finding = {}
                finding['host_ip'] = host_ip
                
                # Extract attributes and data from the ReportItem
                finding['plugin_id'] = report_item.attrib.get('pluginID')
                finding['vulnerability_name'] = report_item.attrib.get('pluginName')
                finding['protocol'] = report_item.attrib.get('protocol')
                finding['port'] = report_item.attrib.get('port')
                
                # Find the child elements to get detailed information
                for tag in report_item:
                    if tag.tag == 'risk_factor':
                        finding['risk_factor'] = tag.text
                    elif tag.tag == 'cvss_base_score':
                        finding['cvss_base_score'] = tag.text
                    elif tag.tag == 'description':
                        finding['description'] = tag.text
                    elif tag.tag == 'solution':
                        finding['solution'] = tag.text
                
                findings.append(finding)
    except ET.ParseError as e:
        print(f"Error parsing XML file: {e}")
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        
    return findings
    
def filter_and_prioritize(findings, min_severity=['Critical', 'High']):
    """
    Filters findings to only include those with a specified severity level.
    
    Args:
        findings (list): A list of dictionaries with vulnerability data.
        min_severity (list): A list of severity strings to filter by.
        
    Returns:
        list: The filtered list of findings, sorted by CVSS score.
    """
    prioritized_findings = [f for f in findings if f.get('risk_factor') in min_severity]
    
    # Sort by CVSS score in descending order
    prioritized_findings.sort(key=lambda x: float(x.get('cvss_base_score', 0)), reverse=True)
    
    return prioritized_findings

def generate_report(prioritized_findings, output_file):
    """
    Generates a CSV report from the prioritized findings.
    
    Args:
        prioritized_findings (list): A list of dictionaries with vulnerability data.
        output_file (str): The path to the output CSV file.
    """
    # Define CSV headers based on the data you've extracted
    headers = ['host_ip', 'vulnerability_name', 'risk_factor', 'cvss_base_score', 'description', 'solution', 'port', 'protocol']
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(prioritized_findings)
        
    print(f"Report generated successfully at: {output_file} 📄")

if __name__ == "__main__":
    nessus_file = 'your_scan_report.nessus'  # Replace with your file path
    output_csv = 'prioritized_vulnerabilities.csv'
    
    # 1. Parse the Nessus report
    all_findings = parse_nessus_report(nessus_file)
    
    if not all_findings:
        print("No findings to process. Exiting.")
    else:
        # 2. Filter for Critical and High vulnerabilities
        critical_and_high = filter_and_prioritize(all_findings, min_severity=['Critical', 'High'])
        
        # 3. Generate a summary report
        generate_report(critical_and_high, output_csv)
        
        print("\nSummary:")
        print(f"Total vulnerabilities found: {len(all_findings)}")
        print(f"Critical & High vulnerabilities prioritized: {len(critical_and_high)}")
        print("Done!")
