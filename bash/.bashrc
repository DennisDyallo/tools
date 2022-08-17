setproxy() {                                                
	npm config set proxy http://proxy.sr.se:8080        
	npm config set https-proxy http://proxy.sr.se:8080  
	yarn config set proxy http://proxy.sr.se:8080       
	yarn config set https-proxy http://proxy.sr.se:8080 
	git config --global http.proxy "proxy.sr.se:8080"   
	export {http,https,ftp}_proxy="proxy.sr.se:8080"    
}                                                           
   
unsetproxy() {                                              
	npm config delete proxy                             
	npm config delete https-proxy                       
	yarn config delete proxy                            
	yarn config delete https-proxy                      
	git config --global --unset http.proxy              
	unset {http,https,ftp}_proxy                        
}

alias gs='git status'
alias gp='git push'
alias go='git checkout' $1

dev='C:\Users\dendya01\Documents\GitHub'