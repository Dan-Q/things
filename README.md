# Dan Q's Things

https://things.danq.me/

Single-page site promoting "things" that [Dan Q](https://danq.me/) has made, around the Web. Static site generated from YML data using [Middleman](https://middlemanapp.com/).

## Dependencies

- Ruby (for Middleman, used to generate the static site)
- Node.js (for Puppeteer, used to take screenshots, and dev serving)

## Installation

- `bundle install`
- `npm install` (and, if Puppeteer didn't fetch it, `npx puppeteer browsers install chrome`)

## Development

- `npm run dev` runs the watcher and the server together, and Ctrl-C stops both. The first build happens on startup.
- `npm run serve` serves build/
- `npm run watch` only does the watching and rebuilding.
- `npm run build` just does a static build

## Usage

Define "things" in `data/things.yml`.

Each thing can have an `image:` (a file in `source/images/`), or a `screenshot:` instead:

```yaml
screenshot:
  url: https://example.com/   # defaults to the thing's own url
  width: 1280                 # optional, default 1920
  height: 720                 # optional, default 1080
```

At build time, Puppeteer screenshots the page into `screenshots/` (cache; ignored by git) and the result is copied to the build's `images/`. A screenshot is retaken only if the cached one is older than 7 days (`Screenshots::CACHE_MAX_AGE` in `lib/screenshots.rb`).

## License

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

- **[GPL v3 license](https://www.gnu.org/licenses/gpl-3.0)**
- Includes fonts from Google Fonts licensed under [SIL OFL](https://opensource.org/licenses/OFL-1.1)
- Copyright 2020 © <a href="https://danq.me/">Dan Q</a>
