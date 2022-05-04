alias got='git'
alias prettyjson='python -m json.tool | pygmentize -l json'
alias docker-ip="docker ps -q | xargs -n 1 docker inspect --format '{{ .Name }} {{range .NetworkSettings.Networks}} {{.IPAddress}}{{end}}' | sed 's#^/##';"
