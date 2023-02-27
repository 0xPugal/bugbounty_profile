#BugBounty automation

subenum() {
	for i in `cat $1`
	do
	subfinder -d $1 -all -silent |tee tmp-subfinder;
	assetfinder --subs-only $1 |tee tmp-assetfinder;
	findomain-linux -t $1 -quiet | tee tmp-findomain;
	amass enum -d $1 -config ~/.config/amass/config.ini | tee tmp-amass;
	gau --subs $1 | unfurl -u domains | tee tmp-gau;
	waybackurls $1 | unfurl -u domains | tee tmp-wayback;
	crobat -s $1 | tee tmp-crobat;
	ctfr.py -d $1 | tee tmp-ctfr; 
	cero $1 | tee tmp-cero; 
	cat tmp-subfinder tmp-assetfinder tmp-findomain tmp-amass tmp-gau tmp-wayback tmp-crobat tmp-ctfr tmp-cero | sort -u | grep ".$1" | tee $1-subs.txt;
	rm tmp-subfinder tmp-assetfinder tmp-findomain tmp-amass tmp-gau tmp-wayback tmp-crobat tmp-ctfr tmp-cero
done
}

naabu() {
	for i in `cat $1`
	do
		naabu -l $1 -port 1-65535 -o $1-ports.txt
	done
}

alive() {
	for i in `cat $1`
	do
		httpx -l $1 -ports 80,8080,443,8443,8880,9000 -o $1-alive.txt
	done
}

subtake() {
	for i in `cat $1`
	do
		subzy -targets $1 --hide_fails --verify_ssl | tee tmp-subzy;
		SubOver -l $1 | tee tmp-subover;
	done
}

nuclei() {
	for i in `cat $1`
	do
		nuclei -l $1 -severity low,medium,high,critical \
			-t nuclei-templates/ \
			-rl 75 -c 10 -o $1-nuclei.txt
		done
	}

nuclei_cve() {
	for i in `cat $1`
	do
		nuclei -l $1 -id cves \
		-rl 200 -c 30 -o $1-cves.txt
	done
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

wayback() {
	for i in `cat $1`
	do 
		echo $1 | gau --subs --threads 10 | tee tmp-gau;
		echo $1 | waybackurls | tee tmp-waybackurls;
		echo $1 | hakrawler -timeout 15 -subs | tee tmp-hakrawler;
		cat tmp-gau tmp-waybackurls tmp-hakrawler | sort -u | uro | tee $1-wayback.txt
		rm tmp-gau tmp-waybackurls tmp-hakrawler
	done
}

jsfiles() {
	for i in `cat $1`
	do
		cat $1 | waybackurls | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | tee tmp-js1;
		cat $1 | gau | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | tee tmp-js2;
		cat $1 | hakrawler | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' | tee tmp-js3;
		subjs -i $1 | tee -a tmp-js4;
		cat tmp-js1 tmp-js2 tmp-js3 tmp-js4 | sort -u | tee -a jsfiles.txt;
		rm tmp-js1 tmp-js2 tmp-js3 tmp-js4
	done
}
