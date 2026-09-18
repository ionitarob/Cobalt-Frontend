FLUTTER := /Users/rionita_work/flutter_clean/bin/flutter

# ── Development (always Beta) ─────────────────────────────────────────────────

run:
	$(FLUTTER) run -d macos --dart-define-from-file=flavors/beta.json

run-ios:
	$(FLUTTER) run -d iPhone --dart-define-from-file=flavors/beta.json

run-android:
	$(FLUTTER) run -d android --dart-define-from-file=flavors/beta.json

run-windows:
	$(FLUTTER) run -d windows --dart-define-from-file=flavors/beta.json

# ── Release builds ────────────────────────────────────────────────────────────

beta:
	$(FLUTTER) build macos --release --dart-define-from-file=flavors/beta.json

beta-ios:
	$(FLUTTER) build ipa --release --dart-define-from-file=flavors/beta.json

beta-android:
	$(FLUTTER) build apk --release --dart-define-from-file=flavors/beta.json

beta-windows:
	$(FLUTTER) build windows --release --dart-define-from-file=flavors/beta.json

prod:
	@echo "⚠️  Building PROD — bundle ID com.maglan.configtoolCobalt (no suffix)"
	@echo "   API → $$(grep API_BASE_URL flavors/prod.json | cut -d'\"' -f4)"
	@read -p "   Continuar? [s/N] " confirm && [ "$$confirm" = "s" ] || exit 1
	$(FLUTTER) build macos --release --dart-define-from-file=flavors/prod.json

prod-ios:
	@echo "⚠️  Building PROD iOS"
	@read -p "   Continuar? [s/N] " confirm && [ "$$confirm" = "s" ] || exit 1
	$(FLUTTER) build ipa --release --dart-define-from-file=flavors/prod.json

prod-android:
	@echo "⚠️  Building PROD Android"
	@read -p "   Continuar? [s/N] " confirm && [ "$$confirm" = "s" ] || exit 1
	$(FLUTTER) build apk --release --dart-define-from-file=flavors/prod.json

prod-windows:
	@echo "⚠️  Building PROD Windows"
	@read -p "   Continuar? [s/N] " confirm && [ "$$confirm" = "s" ] || exit 1
	$(FLUTTER) build windows --release --dart-define-from-file=flavors/prod.json

# ── Utilities ─────────────────────────────────────────────────────────────────

clean:
	$(FLUTTER) clean

test:
	$(FLUTTER) test

.PHONY: run run-ios run-android run-windows \
        beta beta-ios beta-android beta-windows \
        prod prod-ios prod-android prod-windows \
        clean test
