Reconnaissance (recon) in red teaming is the foundational phase where ethical hackers gather intelligence about a target organization to identify vulnerabilities and plan realistic attack simulations.

Core purpose of a Red teamers validate that blue team's defensive measures actually work under real attack conditions. 

Read teamer goals:
- Discover network topology & exploit paths
- Exploit system weaknesses
- Evade detection mechanisms
- Exploit process & people gaps


# Personal Identifiable Information (PII)

Personally Identifiable Information (PII) refers to any data that can identify a specific individual, either on its own or when combined with other information.

Cybercriminals target PII through phishing, data breaches, ransomware, and social engineering, making it essential for individuals and organizations to proactively secure this data.

Most teams use regular expressions, Optical Character Recognition (OCR) and Natural Language Processing (NLP) to search &  filter for PII.

## Types of PII

| Category     |  Examples         |
|--------------|-------------------|
| Personal Information (PI)| - Names <br> - Addresses <br> - Phone numbers <br> - IP address <br> - Photographs <br> - Ethnic origin <br> - Political views |
| Sensitive information | - License number <br> - State Identification number <br> - Geolocation <br> - Genetic data <br> - Consumer's email <br> - Text messages |
| Financial Information |  - Credit card numbers <br> - Social Security Number (SSN) <br> - Payslip <br> - Court records |
| Health Information | - Medical bills |
| Indirect identifiers | - Date of birth <br> - ZIP code <br> - Place of birth <br> - Employment information |

PII is protected under various laws and regulations, including the GDPR (EU), HIPAA (U.S. healthcare), and PCI DSS (payment data)

Organizations must implement safeguards like encryption, access controls, and secure data handling practices to protect PII. 


### PII finders

PII are mostly exposed in text files, images, databases, cloud storage

- [AVG Sensitive data shield](https://www.avg.com/en/signal/avg-sensitive-data-shield-document-protection)
- [CUSpider](https://www.cuit.columbia.edu/content/cuspider-pii-scanning-application)
- [Hawk-Eye](https://github.com/rohitcoder/hawk-eye)
- [Octopii](https://github.com/redhuntlabs/Octopii)
- [Pdscan](https://github.com/ankane/pdscan)
- [PIICatcher](https://github.com/tokern/piicatcher)
- [Presidio](https://github.com/microsoft/presidio)
- [Spirion](https://it.cornell.edu/spirion/scan-confidential-data-windows)


&nbsp;


"⚔️Never stop breaking things - for the right reasons."
