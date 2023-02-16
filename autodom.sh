# Automates subdomain enumeration and nslookups.
# Usage: bash autodom.sh $domain $inscopeIPs
# 
#

# Get the 2nd level domain as a string
name=`echo $1 | rev | cut -f 2 -d "." | rev`

# Create all folders that will be used
mkdir autodom
mkdir autodom/raw_outputs
mkdir autodom/temp

# Create path variables
raws="./autodom/raw_outputs/"
output="autodom"
temp="autodom/temp"

# Create files to be written
touch $output/subdomains-resolving.txt
touch $output/subdomains-inscope.txt
touch $temp/resolved.txt

# Perform the crtsh search
crtsh search -d $1 | tee ./$raws/crtsh_$name


# Get the list of subdomains from the crtsh search
cat ./$raws/crtsh_$name | grep $name | choose 1 | sort -u | ansi2txt >> ./$output/subdomains-all.txt

### OR
## Use an existing list of subdomains
# cat $3 >> ./$output/subdomains-all.txt 


# Perform nslookups on all the subdomains excluding wildcards
for f in `cat $output/subdomains-all.txt | grep -v '*'`; 
do	
	defang=`echo $f | tr [.] [_]`;
	touch "$raws/nslook-$defang";
	nslook_output="$raws/nslook-$defang";
	echo "nslookup $f" >> "$nslook_output";
	nslookup $f >> "$nslook_output";
	answer_found=`cat $nslook_output | grep "Name:" | wc -l`

	# Check if the subdomain resolved, if so save it
	if [ $answer_found -gt 0 ];
	then
		raw_resolved=`cat $nslook_output | grep -A 1 "Name:"`;
		echo $raw_resolved | tr "\ Name:" "\nName:" | grep -v "Name:" | grep -v "Address:" >> "$temp/resolved.txt"
	fi
done;

# Reformat the resolving subdomains into a useful layout.
count=1
for f in `cat $temp/resolved.txt`;
do
	if [ $count -eq 1 ]
	then
		url=$f
		count=2
		continue
	else
		ip=$f
		count=1
	fi
	echo $url $ip >> $output/subdomains-resolving.txt
done

# Clean up the temporary files
rm -r $temp

# Filter out subdomains for in scope external IPs.
while read f;
do
	ip=`echo $f | cut -f 2 -d " "`
	is_inscope=`cat $2 | grep "$ip" | wc -l`
	if [ $is_inscope -gt 0 ]
	then
		echo $f >> $output/subdomains-inscope.txt
	fi
done < $output/subdomains-resolving.txt

cat $output/subdomains-inscope.txt | sort -u | tee $output/subdomains-inscope.txt










