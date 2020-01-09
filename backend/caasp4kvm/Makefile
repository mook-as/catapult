.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	# No-op

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: deploy
deploy:
	./deploy.sh

.PHONY: all
all: deps deploy
