Steps
1. Install Google Cloud SDK: to manipulate cloud resources
2. Install Terraform: to create/destroy clusters from pre-defined specs
3. Create/prepare a project on Google Cloud Platform (GCP)
4. Enable Compute Engine API
5. Create a service account with a role of project editor
6. Create/download a JSON key file for the service account. Note this file can not be re-downloaded. Keep it safe. Or re-create a new one if lost.
7. In the terminal, under this directory, execute							
    $ terraform init
8. In the terminal, under this directory, execute						
    $ terraform apply \
      -var "project_id=<PROJECT ID>" \
      -var "credential_file=<CREDENTIAL FILE NAME>"
The <PROJECT ID> can be found on the GCP console. This command creates all resources on GCP. Users can check the status of these resources on the GCP console.
9. To login to the master node:									
  $ gcloud compute ssh gcp-cluster-login0 --zone=us-central1-a		
Note that even when the GCP console shows the login node and other nodes are ready, it doesn't mean the Slurm is ready. It takes some time for the Slurm to be usable.
10. To destroy the cluster:
  $ terraform destroy \
      -var "project_id=<PROJECT ID>" \
      -var "credential_file=<CREDENTIAL FILE NAME>"

Description of the resources
Node gcp-cluster-controller: where the Slurm daemon is at. This node is always on. NFS server also lives here. /home, /app, /etc/munge are mounted on all other nodes in the cluster. It's why this node has a larger disk.
Node gcp-cluster-login0: the master/login node of the cluster. Users submit jobs from this node. This node is always on.
Node gcp-cluster-compute-0-image: the template node for the Slurm partition debug-cpu. It's down after being successfully created. This cluster will create compute nodes when needed and destroy compute nodes when no job is running after 300 seconds. Compute nodes are created using this template node as the base image. So we don't need to wait for long for the compute nodes to be usable.
Node gcp-cluster-compute-1-image: similar to gcp-cluster-compute-0-image but for the partition debug-gpu.
Node gcp-cluster-compute-<x>-<y>: the actual compute nodes in partition <x> and node ID <y>. These compute nodes are only created and shown when there are Slurm jobs.
Network-related: gcp-cluster-network, gcp-cluster-router, gcp-cluster-nat, and an external IP used by the virtual router. The default SSH port (i.e., 22) is enable by default in the firewall, and it allows connections from any external IP sources. Another opened port for external access is for GCP's command-line tool gcloud. Users can also login to the controller and the master nodes with gcloud.
Note
The creation of the resources may fail at step 8 because of the quotas of the resources. GCP sets very low quotas for C2-type instances and V100 GPUs for new projects. You may need to request a higher quota from GCP.
The nodes in debug-cpu were automatically terminated with no problem when no jobs were running, as described previously. However, those in debug-gpu did not work. I have not figured out what went wrong. So be careful the bill of those GPU nodes.
It seems NVIDIA driver was not automatically installed, though I didn't spend much time investigating this issue.
