.PHONY: all clean re

all:
	vagrant up

clean:
	vagrant destroy -f
	rm -f shared/kubeconfig.yaml shared/k3s_token
	rm -rf .vagrant .vagrant.d

re: clean all
