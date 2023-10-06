# Load the .env file and store common variables into environment
source ~/.env

setproxy() {                              
	echo "Setting proxy to: $PROXY"
	npm config set proxy $PROXY        
	npm config set https-proxy $PROXY 
	yarn config set proxy $PROXY      
	yarn config set https-proxy $PROXY
	git config --global http.proxy $PROXY
	export {http,https,ftp}_proxy=$PROXY
	export no_proxy="localhost,127.0.0.1,.sr.se"
}                                                           
   
unsetproxy() {                                              
	npm config delete proxy                             
	npm config delete https-proxy                       
	yarn config delete proxy                            
	yarn config delete https-proxy                      
	git config --global --unset http.proxy              
	unset {http,https,ftp}_proxy                        
}

# You can call these scripts from a bash shell