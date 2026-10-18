# Screenshot index

These are actual Android emulator captures, not mockups. `phone/` and `tablet/` show the installed release app. `qa/` shows the real app in the separate debug integration-test build using live DummyJSON responses.

## Phone release app

1. [Catalogue](phone/01-catalogue.png)
2. [Product details](phone/02-product-details.png)
3. [Persisted cart and badge](phone/03-cart.png)
4. [Order confirmation](phone/04-order-confirmation.png)
5. [Profile](phone/05-profile.png)
6. [Persistent saved item](phone/06-saved.png)
7. [Airplane-mode cached catalogue and offline banner](phone/06-offline.png)
8. [Landscape at 1.3× text, scrolled to reachable retry](phone/07-landscape-large-text-offline.png)
9. [Portrait at 1.3× text, successful retry after network restoration](phone/08-large-text-recovered.png)
10. [Persistent dark-mode preference](phone/09-dark-mode.png)

## Tablet release app

Both use 1.3× system text on a Pixel C API 26 emulator.

1. [Landscape master-detail and navigation rail](tablet/01-landscape-master-detail.png)
2. [Portrait three-column grid](tablet/02-portrait-grid.png)

## Live integration-test evidence

1. [HTTP 400 invalid login](qa/01-invalid-login.png)
2. [HTTP 500 friendly error and retry](qa/02-server-error.png)
3. [HTTP 404 product not found](qa/03-product-not-found.png)
4. [Three-second network delay skeleton](qa/04-slow-network-loader.png)
5. [Receive timeout and retry](qa/05-timeout.png)
6. [Protected request, rejected refresh and safe session expiry](qa/06-session-expired.png)

See [QA report](../docs/QA_REPORT.md) for device dimensions, tested scope and distinctions between release checks and the test entry point.
