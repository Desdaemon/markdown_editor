commit := `git rev-parse --short HEAD`

run *args:
	flutter run --dart-define=commit={{commit}} {{args}}

build-web *args:
	flutter build web --dart-define=commit={{commit}} {{args}}
