helm repo add gitlab https://charts.gitlab.io
helm repo update

helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set config.token=<SEU-TOKEN> \
  --set config.kasAddress=wss://kas.gitlab.com \
  --set image.tag=v18.4.0