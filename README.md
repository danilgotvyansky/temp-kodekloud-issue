# temp-kodekloud-issue #
Temporary repository to show files and the issue on Kodekloud GCP playground

## Steps to reproduce the issue ##
1. Clone repo to your local env.
2. Install terraform (my version is Terraform v1.6.3)
3. Launch a new GCP playground on Kodekloud and update values `project_id` and `compute_service_account_email` with the ones from your playground project.
4. Run: 
```commandline
gcloud auth login
```
and copy the opened link in the same browser tab as your playground account. Click `Allow`.
5. Set your project ID:
```commandline
gcloud config set project <project-id>
```
6. Do the same with command:
```commandline
gcloud auth application-default login
```
7. Do Terraform init:
```commandline
terraform init
```
8. Apply `network` module:
```commandline
terraform apply --target=module.network
```
9. Apply `instance` module:
```commandline
terraform apply --target=module.network
```
10. Go to **VM instances** page and copy your gcloud connection command to the created instance:
```commandline
gcloud compute ssh --zone "us-central1-a" "instance-1" --project "<project-id>"
```
11. Connect to the instance using the copied command.
12. On the instance install docker and configure it.
```commandline
sudo apt install docker.io -y
sudo groupadd docker
sudo usermod -aG docker $USER
```
13. Re-connect to instance to apply changes.
14. Create `Dockerfile
```commandline
echo "FROM httpd:2.4
RUN echo "OK" > /usr/local/apache2/htdocs/index.html" > Dockerfile
```
15. Build Apache container:
```commandline
docker build -t apache-healthcheck .
docker run -d -p 80:80 apache-healthcheck
```
16. Visit `http://<instance-public-ip>:80` and you will see OK
17. Apply `load-balancer` module
```commandline
terraform apply --target=module.load-balancer
```

## Issue ##
After all these steps if you copy created `Frontend IP`on `traffic-load-balancer` details, and open it in browser, you will always see timeout.

Healthchecks are passed and the instance is healthy, firewall logs show that the traffic for the healthcheks are allowed too. I think I misconfigured something in Network configurations for the forwarding rule.

I also tried to create the same thing with default network but it failed the same.

Will appreciate any help and attach any additional info/logs if needed.