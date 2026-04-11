set shell := ['/bin/sh', '-cu']

import './just.d/hugo.just'
import './just.d/gitsecret.just'
import './just.d/vendir.just'

# Default invocation prints the command list
default:
	@just --list

# Show this help message
help:
	@just --list

# Interactive project menu
menu:
	@./scripts/interactive.sh \
		"Hugo::just hugo" \
		"Sync dependencies::just sync" \
		"Encrypt secrets::just encrypt" \
		"Decrypt secrets::just decrypt" \
		"Install tools::just install-tools"

# Install mise-managed tools
install-tools:
	@mise install
