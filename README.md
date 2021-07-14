# Docker image to detect outdated Helm charts

This docker image uses https://github.com/fabmation-gmbh/helm-whatup to check
whether there are outdated Helm charts installed in your cluster. Helm 3 only.

* It is installed as a Kubernetes cron job
  * needs a service account with sufficient privileges (read-only permissions)
* Supports two usage modes: either
  * the job fails if a chart is outdated (which integrates into your existing monitoring), or
  * it mails you a list of outdated charts (if recipient and SMTP configured)
* Supports to send mails only on changes (if `/data` is a persistent volume)

## Repository address

GitHub: [aspettl/docker-helm-outdated](https://github.com/aspettl/docker-helm-outdated)

## Docker image

DockerHub image (built using GitHub action): [aspettl/docker-helm-outdated](https://hub.docker.com/r/aspettl/docker-helm-outdated)

## How to install / example

See the example resource definitions in the `deploy` folder. This example includes
* a cron job that executes once a night
* a service account with (cluster-wide) read-only permissions, needed to detect all Helm charts
* a config map with a custom `add_repos.sh` script to add the Helm repositories
* a secret with SMTP credentials for sending mails
* a persistent volume claim, needed to send emails only on changes

Use `kubectl create job --namespace=helm-outdated --from=cronjob/helm-outdated helm-outdated-test`
to schedule a job immediately.

## License

MIT license, see [LICENSE](https://github.com/aspettl/docker-helm-outdated/blob/master/LICENSE)
