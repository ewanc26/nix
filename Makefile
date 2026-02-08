.PHONY: help switch boot test update clean fmt check

help:
	@echo "NixOS Configuration Management"
	@echo ""
	@echo "Available targets:"
	@echo "  switch    - Build and activate configuration (default)"
	@echo "  boot      - Build configuration for next boot"
	@echo "  test      - Build and test configuration without setting default"
	@echo "  update    - Update flake inputs"
	@echo "  clean     - Remove old generations and run garbage collection"
	@echo "  fmt       - Format Nix files"
	@echo "  check     - Check flake for errors"

switch:
	sudo nixos-rebuild switch --flake .#laptop

boot:
	sudo nixos-rebuild boot --flake .#laptop

test:
	sudo nixos-rebuild test --flake .#laptop

update:
	nix flake update
	@echo "Don't forget to run 'make switch' to apply updates"

clean:
	sudo nix-collect-garbage -d
	nix-collect-garbage -d
	@echo "Cleaned up old generations"

fmt:
	nix fmt

check:
	nix flake check
