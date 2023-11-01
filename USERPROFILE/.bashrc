# Load the .env file and store common variables into environment
source ~/.env

setproxy() {            
	echo "Setting proxy environment variables to: $SR_PROXY"
	export {http,https,ftp}_proxy=$SR_PROXY
    export {HTTP,HTTPS,FTP}_PROXY=$SR_PROXY

	echo "Setting no_proxy variables to: $NO_PROXY"
	export no_proxy=$NO_PROXY
    export NO_PROXY=$NO_PROXY

	echo "Setting npm proxy to: $SR_PROXY"
	npm config set proxy $SR_PROXY        
	npm config set https-proxy $SR_PROXY 
	
	echo "Setting yarn proxy to: $SR_PROXY"
	yarn config set proxy $SR_PROXY      
	yarn config set https-proxy $SR_PROXY

	echo "Setting git proxy to: $SR_PROXY"
	git config --global http.proxy $SR_PROXY
}                                                           
   
unsetproxy() {                                              
	npm config delete proxy                             
	npm config delete https-proxy                       
	yarn config delete proxy                            
	yarn config delete https-proxy                      
	git config --global --unset http.proxy              
	unset {http,https,ftp,no}_proxy                        
    unset {HTTP,HTTPS,FTP,NO}_PROXY
}

# You can call these scripts from a bash shell