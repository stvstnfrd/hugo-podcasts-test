REQUIREMENTS_SYSTEM=hugo pandoc xmllint
ifneq (,$(shell command -v apt-get))
APT_REQUIREMENTS_INPUT=lib/requirements.apt.txt
APT_REQUIREMENTS_OUTPUT_DIRECTORY=tmp
APT_REQUIREMENTS_OUTPUT=$(APT_REQUIREMENTS_OUTPUT_DIRECTORY)/$(notdir $(APT_REQUIREMENTS_INPUT))
APT_INSTALL=sudo apt-get install -y

.PHONY: requirements-system
requirements-system: $(APT_REQUIREMENTS_OUTPUT)  ### Install system requirements
$(APT_REQUIREMENTS_OUTPUT): $(APT_REQUIREMENTS_INPUT)
	while read line; do \
		line=$$(echo "$${line}" | sed 's/^ +//; s/ *#.*$$//;'); \
		if [ -n "$${line}" ]; then \
			package=$$(echo "$${line}" | awk '{print $$1}') ; \
			command=$$(echo "$${line}" | awk '{print $$2}') ; \
			if [ -n "$${command}" ]; then \
				if command -v "$${command}" >/dev/null; then \
					continue; \
				fi \
			fi ; \
			if [ -n "$${package}" ]; then \
				$(APT_INSTALL) "$${package}"; \
			fi ; \
		fi ; \
	done <'$(APT_REQUIREMENTS_INPUT)'
	test -d '$(APT_REQUIREMENTS_OUTPUT_DIRECTORY)' || mkdir '$(APT_REQUIREMENTS_OUTPUT_DIRECTORY)'
	cp '$(<)' '$(@)'
else
.PHONY: requirements-system
requirements-system:  ### Install system requirements
ifneq (,$(REQUIREMENTS_SYSTEM))
	@echo "WARN:  We were unable to detect your package manager,"
	@echo "WARN:  so you will need to ensure the following"
	@echo "WARN:  executables are available:"
	@result=0; \
	for bin in $(REQUIREMENTS_SYSTEM); do \
		if ! command -v "$${bin}" >/dev/null; then \
			echo "ERROR:         $${bin} (NOT installed)"; \
			result=1; \
		else \
			echo "WARN:          $${bin} (installed)"; \
		fi ; \
	done ; \
	exit $${result}
endif
endif
