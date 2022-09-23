GREEN="\[\033[1;32m\]"
WHITE="\[\033[1;37m\]"
YELLOW="\[\033[1;33m\]"
PS1="\w $YELLOW \$(parse_git_branch): $WHITE"

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

gd(){
    git diff origin/master $1 $2 $3 $4 $5 $6 $7 $8 $9
}

cl() {
    clear
    pwd
}
 
home() {
    cd /c/dev
}

gdf(){
	git fetch
	git diff FETCH_HEAD
}

gs() {
    git status $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
ga() {
    git add $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
gc() {
    git commit -m "$2" $3 $4 $5 $6 $7 $8 $9
}

go() {
	git checkout $1 $2 $3 $3 $4 $5 $6 $7 $8 $9
}
 
gf() {
    git fetch $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
gr() {
    git rebase $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
gm() {
    git merge $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
gp() {
    git push $1 $2 $3 $4 $5 $6 $7 $8 $9
}

gpr() {
    git pull --rebase
}
gl() {
    git log --graph --pretty=format:'%Cred%h%Creset %Cgreen%cr %C(bold yellow)%an %Creset- %s  %Creset' --abbrev-commit $1 $2 $3 $4 $5 $6 $7 $8 $9
}
 
qc() {
    git add --all
    git commit -m "0: refactoring $1"
}

gfm() {
	git fetch origin main:main
}

setproxy() {
	SR_PROXY=http://proxy.sr.se:8080
	echo "Setting proxy $SR_PROXY for npm, yarn, git and bash proxy variables"
    npm config set proxy $SR_PROXY
    npm config set https-proxy $SR_PROXY
    yarn config set proxy $SR_PROXY  
    yarn config set https-proxy $SR_PROXY
    git config --global http.proxy $SR_PROXY
    git config --global https.proxy $SR_PROXY
    export {http,https,ftp,all}_proxy=$SR_PROXY
    export no_proxy=localhost,.sr.se
}  

unsetproxy() {
    npm config delete proxy                             
    npm config delete https-proxy                       
    yarn config delete proxy                            
    yarn config delete https-proxy
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    unset {http,https,ftp}_proxy
    unset no_proxy
    unset all_proxy
}

export NPM_TOKEN=
