# Docker image to detect outdated Helm charts

This docker image uses https://github.com/fabmation-gmbh/helm-whatup to check
whether there are outdated Helm charts installed in your cluster. Helm 3 only.

* It is installed as a Kubernetes cron job
  * needs a service account with sufficient privileges (read-only permissions)
* Supports two usage modes: either
  * the job fails if a chart is outdated (which integrates into your existing monitoring), or
  * it mails you a list of outdated charts (if recipient and SMTP configured)
* Supports to send mails only on changes (if `/data` is a persistent volume)

## License

MIT license, see [LICENSE](https://github.com/aspettl/docker-helm-outdated/blob/master/LICENSE)
