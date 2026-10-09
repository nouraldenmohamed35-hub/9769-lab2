DIR ?= test
MALICIOUS_DIR ?= quarantine
INTERVAL ?= 5

.PHONY: all setup antivirus restore

all: antivirus

# Pre-build step: create the quarantine directory if it does not exist
setup:
	mkdir -p $(MALICIOUS_DIR)

antivirus: setup
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

restore: setup
	./restore.sh $(DIR) $(MALICIOUS_DIR)
