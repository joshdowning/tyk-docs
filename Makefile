gen-menu: hugo
	python3 scripts/menu_generator.py scripts/menu-gen/data-bank.csv scripts/menu-gen/pages-list.csv tyk-docs/public/urlcheck.json

hugo:
	cd tyk-docs && hugo

