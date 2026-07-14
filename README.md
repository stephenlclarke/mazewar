# Mazewar

<!-- markdownlint-disable MD013 -->
[![CI](https://github.com/stephenlclarke/mazewar/actions/workflows/ci.yml/badge.svg)](https://github.com/stephenlclarke/mazewar/actions/workflows/ci.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=bugs)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=coverage)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=sqale_index)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=stephenlclarke_mazewar&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=stephenlclarke_mazewar)

Mazewar is a native macOS SwiftUI remake of the retained 1986 Unix/X11 MazeWar source. It uses the original fixed 32×16 Alto maze bitmap, a first-person perspective, top-down position map, scorecard, side peeking, and the source game's one-second shot and scoring rules.

## Requirements

- macOS 14 or later
- Swift 6.0 or later

## Build and run

```sh
swift build
swift test
./script/build_and_run.sh
```

The app reproduces the original movement keys through its Mazewar menu and visible controls:

- `A`: about face
- `S`: turn left
- `D`: move forward one maze square
- `F`: turn right
- `Space`: move backward one maze square
- `[` / `]`: peek left / right around an open corner
- `R`: fire

`Command-Q` is the macOS equivalent of the historical `Q` exit key. Firing immediately costs one point. A shot delivered after one second costs the target five points and respawns them; a confirmed hit leaves the shooter ten points ahead overall.

Start a Nearby Session to use local peer discovery. Peers exchange position, shot, and hit messages, while preserving the legacy game's delayed shot resolution. The app deliberately does not attempt to interoperate with the historical UDP protocol retained under `original/`.

## Quality workflow

```sh
make coverage-check
make sonar
```

`make coverage` writes `coverage.lcov` and converts it to SonarQube generic `coverage.xml`; `make sonar` refuses to scan without that report. The SonarCloud project key is `stephenlclarke_mazewar`.

## Legacy source

The original C/X11 implementation, fixed maze bitmap, and historical networking code live in [`original/`](original) as a preserved reference. The Swift package is a separate native implementation and does not compile or link that source.

## License

New Swift sources are MIT licensed. The retained historical source has its original Digital Equipment Corporation, Xerox, and X Consortium notices; see [LICENSE](LICENSE).

<!-- markdownlint-enable MD013 -->
