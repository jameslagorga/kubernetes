# This Makefile provides a command to refresh the NFS storage.
# WARNING: This will permanently delete all data on the NFS volume.

.PHONY: refresh-nfs

restore-nfs: delete-nginx delete-pvc delete-pv apply-pv apply-pvc apply-nginx-conf apply-nginx

apply-nginx:
	kubectl apply -f nginx-deployment.yaml

apply-nginx-conf:
	kubectl create configmap nginx-conf --from-file=nginx.conf --dry-run=client -o yaml | kubectl apply -f -

delete-nginx:
	kubectl delete deployment nginx-deployment --ignore-not-found

delete-pv:
	@kubectl delete pv filestore-pv --ignore-not-found

apply-pv:
	kubectl apply -f persistent_volume.yaml
	@echo "Waiting for PV to become available..." && sleep 2

apply-pvc:
	kubectl apply -f persistent_volume_claim.yaml
	@echo "Waiting for PVC to bind..." && sleep 2

delete-pvc:
	@kubectl get pods,deployments,jobs,cronjobs,statefulsets,daemonsets,replicasets --all-namespaces -o jsonpath="{range .items[?(@.spec..volumes[*].persistentVolumeClaim.claimName=='filestore-pvc')]}{.kind}/{.metadata.name}{' '}{end}" | xargs -r -n 1 kubectl delete --ignore-not-found
	@kubectl delete pvc filestore-pvc --ignore-not-found

