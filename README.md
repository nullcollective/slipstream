This script will automatically locate a Windows Partition and mount it, and find and exfiltrate files matching specific categories. The slipstream script is best used when combined with a fast, low-overhead Linux bootable drive (ie: a small buildroot image).

NEW FEATURE: Payload System

```
$ ./slipstream.sh -h
[: :|:::] slipstream by nullcollective [: :|:::]
╭∩╮(ô¿ô)╭∩╮ DESTROY FASCISM ╭∩╮(ô¿ô)╭∩╮

Usage: ./slipstream.sh [OPTIONS]
Options:
 -h      Display this help message
 -l      List Available Payloads
 -x      Runs Script with Specified Payload
-------------------------------------------

$ ./slipstream.sh -l
[: :|:::] slipstream by nullcollective [: :|:::]
╭∩╮(ô¿ô)╭∩╮ DESTROY FASCISM ╭∩╮(ô¿ô)╭∩╮

AVAILABLE PAYLOADS
-------------------------------------------
[-->] payload_exfiltrate_data
[-->] payload_firefox_copy
[-->] payload_host_poison
[-->] payload_samcopy
[-->] payload_wipe_all_data
-------------------------------------------
```
