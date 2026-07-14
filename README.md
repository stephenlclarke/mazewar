# Mazewar

<!-- markdownlint-disable MD013 -->
[![CI](https://github.com/stephenlclarke/mazewar/actions/workflows/ci.yml/badge.svg)](https://github.com/stephenlclarke/mazewar/actions/workflows/ci.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=coverage)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
<!-- markdownlint-enable MD013 -->

Mazewar is a native macOS SwiftUI reimagining of the 1986 multiplayer maze
game. It provides a generated arena, familiar movement and facing controls,
shooting feedback, a scoreboard, and nearby-peer discovery that shares each
player's movement state.

## Requirements

- macOS 14 or later
- Swift 6.0 or later

## Build and run

```sh
swift build
swift test
./script/build_and_run.sh
```

Use the toolbar or keyboard shortcuts: `W` and `S` move, `A` and `D` turn, and
Space fires. Start a LAN session from the sidebar to discover nearby Mazewar
players.

## Quality workflow

```sh
make coverage-check
make sonar
```

`make coverage` writes `coverage.lcov` and converts it to SonarQube generic
`coverage.xml`; `make sonar` refuses to scan without that report. Import
SonarCloud project key `stephenlclarke_mazewar` for the quality and coverage
badges to populate.

## Legacy source

<!-- markdownlint-disable-next-line MD013 -->
The original C/X11 implementation and its historical networking code live in [`original/`](original) as reference, but are not part of the Swift package.

## License

New Swift sources are MIT licensed. The retained historical source has its
original Digital Equipment Corporation, Xerox, and X Consortium notices; see
[LICENSE](LICENSE).
