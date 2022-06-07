# Overview
Qualys SSL Report Grading for PRTG is a custom PowerShell script that queries the Qualys SSL Labs Service and allows you to grade a (public) web property's SSL Settings

# Installation
- Copy the *.ps1 and *.psm1 files to the `PRTG Network Monitor\Custom Sensors\EXEXML` folder on your Probe(s) where you want to use the Sensor from.

- Copy the *.ovl files to the `PRTG Network Monitor\lookups\custom` folder on your Probe(s) where you want to use the Sensor from.

- Create a new Sensor of type `EXE/script Advanced` (Make sure you use Advanced!)

- Give the Sensor an appropriate Name (e.g. `SSL Grade`)

- Select `QualysSSLReport.ps1` in EXE/Script

- Use `-ServerName %host` as a parameter, which uses the hostname of the parent device, or specify a name directly using e.g. `-ServerName microsoft.com`

- It's a good idea to set a Mutex to not overwhelm the Qualys API or get throttled when you have multiple sensors with this type. Use e.g. `michelz.prtg.qualys.mutex` as value

- Set the timeout to an appropriate value (it's not uncommon that this scan takes 10 minutes - so we recommend at least 600 seconds)

- Set the scanning interval to something very low, like 6 hours. We don't want to overwhelm the Qualys API or get throttled. The result also doesn't change often.
Use at least 1 hour.

# Release Notes
| Date       | Version       | Description |
|------------|---------------|-------------|
|2019-11-22  | Version 0.1   | Initial Version |
|2021-03-19  | Version 0.1.1 | Updated input from "host" to match parameter name of function "ServerName" |
|2022-06-07  | Version 0.1.2 | Updated error handling |
|2022-06-07  | Version 0.1.3 | Improve cache behavior |