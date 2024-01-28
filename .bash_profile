#BugBounty automation

sub() {
	subfinder -d $1 -all -silent |anew $1-subs.txt
	assetfinder --subs-only $1 |anew $1-subs.txt
	shuffledns -d $1 -w $wordlists.txt -r $resolvers.txt -silent | $1-subs.txt
	findomain --target $1 --quiet | anew $1-subs.txt
	amass enum -passive -noaltns -norecursive -d $1 | anew $1-subs.txt
	gau --subs $1 | unfurl -u domains | anew $1-subs.txt
}

naabu() {
	naabu -l $1 -top-ports full -rate 5000 -nmap -o $1-ports.txt
}

httpxx() {
	httpx -l $1 -td -sc -cl -ct -title -ws -threads 500 -o $1-httpx.txt
}

nucleix() {
	nuclei -l $1 \
	-eid expired-ssl,tls-version,ssl-issuer,deprecated-tls,revoked-ssl-certificate,self-signed-ssl,kubernetes-fake-certificate,ssl-dns-names,weak-cipher-suites,mismatched-ssl-certificate,untrusted-root-certificate,metasploit-c2,openssl-detect,default-ssltls-test-page,wordpress-really-simple-ssl,wordpress-ssl-insecure-content-fixer,cname-fingerprint,mx-fingerprint,txt-fingerprint,http-missing-security-headers,nameserver-fingerprint,caa-fingerprint,ptr-fingerprint,wildcard-postmessage,symfony-fosjrouting-bundle,exposed-sharepoint-list,CVE-2022-1595,CVE-2017-5487,weak-cipher-suites,unauthenticated-varnish-cache-purge,dwr-index-detect,sitecore-debug-page,python-metrics,kubernetes-metrics,loqate-api-key,kube-state-metrics,postgres-exporter-metrics,CVE-2000-0114,node-exporter-metrics,kube-state-metrics,prometheus-log,express-stack-trace,apache-filename-enum,debug-vars,elasticsearch,springboot-loggers \
	-ss template-spray \
	-ept ssl,tcp,network,code,whois,javascript,websocket \
	-es info,unknown \
	-rl 500 -c 100 -bs 500 \
	-o $1-nuclei.txt
}

ffuf() {
	dom=$(echo $1 | unfurl format %s%d)
	ffuf -c -w wordlists.txt \
		-recursion -recursion-depth 5 \
		-H "User-Agent: Mozilla Firefox Mozilla/5.0" \
		-H "X-Originating-IP: 127.0.0.1" \
		-H "X-Forwarded-For: 127.0.0.1"
		-H "X-Forwarded: 127.0.0.1"
		-H "Forwarded-For: 127.0.0.1"
		-H "X-Remote-IP: 127.0.0.1"
		-H "X-Remote-Addr: 127.0.0.1"
		-H "X-ProxyUser-Ip: 127.0.0.1"
		-H "X-Original-URL: 127.0.0.1"
		-H "Client-IP: 127.0.0.1"
		-H "True-Client-IP: 127.0.0.1"
		-H "Cluster-Client-IP: 127.0.0.1"
		-H "X-ProxyUser-Ip: 127.0.0.1"
		-ac -mc all -of csv -o $1-ffuf.csv
	}

ffuf_multi() {
	ffuf -c -w $1.txt:URL \
	-w $wordlists:FUZZ \
	-u URL/FUZZ \
	-mc all -of json -o $1-ffuf.json
}

ffuf_json_2_txt() {
	cat $1-ffuf.json | jq | grep "url" | sed 's/"//g' | sed 's/url://g' | sed 's/^ *//' | sed 's/,//g' | anew $1-ffuf.txt
}

spider() {
	echo $1 | gau --subs --threads 10 | anew urls;
	echo $1 | waybackurls | anew urls;
	echo $1 | hakrawler -timeout 15 --subs | anew urls;
	katana -u $1 -jc -kf -silent | anew urls
}

waymore() {
	python3 waymore.py -i $1 -mode U -oU $1-waymore.txt
}

jsfiles() {
	cat $1 | waybackurls | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | anew js1;
	cat $1 | gau | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | anew js1;
	cat $1 | hakrawler | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | anew js1;
	subjs -i $1 | anew js1;
	katana -u $1 -jc -kf -silent | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | anew js1;
}

portscan() {
	cat $1 | parallel -j 100 'echo {} | naabu -silent -rate 500 -nmap | anew $-ports.txt'
}
