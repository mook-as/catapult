.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: clean
clean:
	./destroy.sh

.PHONY: deps
deps:
	# no-op

.PHONY: deps-caasp4os
deps-caasp4os:
	./docker_skuba.sh

.PHONY: caasp4os-deploy
caasp4os-deploy:
	./deploy.sh

.PHONY: caasp-prepare
caasp-prepare:
	./prepare.sh

.PHONY: all
all: deps-caasp4os caasp4os-deploy caasp-prepare
