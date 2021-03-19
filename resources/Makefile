# This Makefile is for internal use only. Please see top-level
# tools/documentation. This file focuses on running the tools. It
# doesn't deal with setting up the environment at all.

ifndef PLEASE
$(error "You should use the 'rax-docs' command for all documentation	\
	tasks. If you think you know what you're doing, say PLEASE")
endif

ifdef JENKINS_URL
# Running in Jenkins, so everything has to happen within the workspace
styles_dir = styles
temp_dir = ./
template_path = .rax-docs/repo/resources/vale.ini.template
else
# Running in Docker, so resources will be where they were installed in
# the image
styles_dir = /styles
temp_dir = /tmp
template_path = /src/.rax-docs/repo/resources/vale.ini.template
endif

.PHONY: clean html htmlvers spelling vale test

clean:
	rm -rf _build/*

test: spelling vale
	doc8
	@echo "All tests completed"
	@echo

html:
	sphinx-build -E -q -b html -d _build/doctrees . _build/html
	@echo "HTML finished. The pages are in $(OUTER_PWD)/docs/_build/html"
	@echo

vale: html
	TEMP=$$(mktemp --tmpdir=$(temp_dir)) && \
	sed 's#{{styles_path}}#$(styles_dir)#' < $(template_path) > "$$TEMP" && \
	vale --config "$$TEMP" _build/html/* | tee _build/vale_output.txt || true
	@echo "Vale Finished. Output is in $(OUTER_PWD)/docs/_build/vale_output.txt"
	@echo

htmlvers:
	sphinx-versioning -l conf.py build docs _build/html/
	@echo "Versioned HTML. The HTML pages are in $(OUTER_PWD)/docs/_build/html"
	@echo

spelling: html
	sphinx-build -W -b spelling -d _build/doctrees . _build/spelling
	@echo "Spell check finished. The spellcheck output is in $(OUTER_PWD)/docs/_build/spelling"
	@echo
