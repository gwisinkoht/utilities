import ipaddress
import sys
iplist=[str(ip) for ip in ipaddress.IPv4Network(sys.argv[1])]
for ip in iplist:
	print(ip)
