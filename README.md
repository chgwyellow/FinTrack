# FinTrack

[English](README.md) · [繁體中文](README.zh-TW.md)

[![Version](https://img.shields.io/github/v/tag/chgwyellow/FinTrack?label=version)](https://github.com/chgwyellow/FinTrack/tags)
[![Downloads](https://img.shields.io/github/downloads/chgwyellow/FinTrack/total?label=downloads)](https://github.com/chgwyellow/FinTrack/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://github.com/chgwyellow/FinTrack/releases)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-native-orange?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![SQLite](https://img.shields.io/badge/SQLite-local-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)

<p align="center">
  <img src="docs/assets/fintrack-hero.png" alt="FinTrack Overview and Portfolio" width="100%">
</p>

<h3 align="center">Your finances. One clear picture.</h3>

<p align="center">
  A private, local-first personal finance app for macOS.<br>
  Track what you own, what you owe, how your investments are performing,
  and how your net worth changes over time.
</p>

## Your financial life, in one place

FinTrack brings the different parts of your personal finances together so you
can understand your overall financial position without handing your financial
information to an online account or subscription service.

Manage cash and other assets, liabilities, Taiwan and U.S. investments,
dividends, recurring investment plans, foreign-currency balances, and income
and expense items while keeping your financial database on your own Mac.

Market prices and exchange rates are fetched when needed to calculate current
values. Your manually entered information, transactions, balances, and
snapshots remain stored locally.

## What you can do with FinTrack

### See your complete financial picture

Track assets, liabilities, investments, and net worth together instead of
maintaining separate lists or spreadsheets. Create snapshots to see how your
net worth changes over time. Edit balances directly or record an increase or
decrease as a balance adjustment, and group items by asset or liability type.

### Track your investment portfolio

Track Taiwan and U.S. stocks and ETFs in their original currencies. Record
holdings and purchases, then review portfolio value, allocation, average cost,
capital gains, and daily profit and loss. Dividends are recorded separately and
included in total investment returns.

FinTrack is designed for portfolio tracking and personal financial analysis,
not active trading.

### Keep recurring investments organized

Create recurring investment plans and enter the purchases you actually make.
FinTrack keeps the investment plan separate from completed purchases so your
portfolio reflects your actual holdings.

### Track dividends and income

Record and edit dividends for your holdings. Organize income, expenses, and
savings in the income statement, with a group and one level of detail beneath
each group. Leaf items can optionally link to an existing account or a saved
custom account name.

### Manage foreign currencies

Track foreign-currency balances and transactions, including exchanges. Review
current and average exchange rates and the NTD equivalent of each balance.

### Build a history of your net worth

Create manual or scheduled net worth snapshots and view history across 1M, 3M,
6M, 1Y, or all-history ranges. Scroll horizontally within the chart to inspect
older observations. The Y-axis scales to the selected time range. A manual
snapshot records today's date; the scheduled snapshot records the previous
calendar day. Multiple snapshots on one date replace that day's value.

## Private by design

FinTrack does not require an account or sign-in. It does not operate a backend
server for storing user data. Your financial database is stored locally on
your Mac using SQLite and is never uploaded to FinTrack.

External public data sources are contacted only when information such as market
prices or exchange rates is needed.

> **Your financial information stays on your Mac.**

## What FinTrack is — and what it isn't

FinTrack is a **personal finance tracking and analysis tool**. It is designed
to help answer questions such as:

- What do I own?
- What do I owe?
- What is my current net worth?
- How is my investment portfolio performing?
- How is my money allocated?
- How has my financial position changed over time?

FinTrack is not a brokerage or trading terminal. It does not place stock
orders, connect to brokerage accounts, automatically import brokerage
transactions, move money, or execute recurring investments automatically.

Completed investment transactions and recurring purchases must be entered
manually.

## Core features

- **Financial Overview** — Track assets, liabilities, investments, and net worth
  in one place
- **Net Worth History** — Create manual and scheduled snapshots, browse history
  horizontally, and see the Y-axis adapt to the selected date range
- **Portfolio Tracking** — Track Taiwan and U.S. stocks and ETFs in their
  original currencies
- **Portfolio Analytics** — View portfolio value, allocation, capital gains,
  and daily profit and loss
- **Recurring Investments** — Manage recurring investment plans and completed
  purchases
- **Dividends & Income** — Record dividends and organize income, expenses, and
  savings, with optional account links
- **Foreign Currency** — Track foreign-currency balances, exchange rates, and
  transactions
- **Local Storage** — Store financial information locally using SQLite
- **Preferences** — Choose English or Traditional Chinese, appearance, and
  portfolio performance colors

## Download the latest release

### Download step by step

1. Open [GitHub Releases](https://github.com/chgwyellow/FinTrack/releases).
2. Open the newest release, currently `v0.1.7`.
3. Scroll to **Assets** and expand it if necessary.
4. Download **`FinTrack-0.1.7.zip`**.
5. Open the downloaded ZIP from your Downloads folder.
6. Move the extracted `FinTrack.app` to `/Applications`.
7. Right-click the app and select **Open** on its first launch.
8. If macOS still blocks it, open **System Settings → Privacy & Security** and
   select **Open Anyway**.

The current release supports Apple Silicon Macs only. It uses an ad-hoc
signature and is not notarized, so macOS may require you to allow it in Privacy
& Security. Future releases may use a different version number or filename.

## Data storage and backup

On first launch, FinTrack automatically creates its application-support folder,
SQLite database, and database tables. No manual setup is required.

The database is stored at:

```text
~/Library/Application Support/FinTrack/personal_finance.db
```

Each macOS user account has its own database. Installing, moving, or updating
the app does not remove this database.

Before testing a new release, back up the database:

```bash
cp "$HOME/Library/Application Support/FinTrack/personal_finance.db" \
   "$HOME/Library/Application Support/FinTrack/personal_finance.backup.db"
```

## Getting started

1. Add your assets and liabilities from **Overview**.
2. Add stocks or ETFs from **Portfolio** and manage their actual purchases.
3. Use **Recurring Investment** to manage recurring investment plans.
4. Add foreign-currency balances and transactions from **Foreign Currency**.
5. Create a snapshot from **Overview** to start tracking your net worth history.
6. Open **Help** inside FinTrack for page-specific guidance.

Market prices and exchange rates are refreshed when relevant pages are opened.
The scheduled net-worth snapshot runs at the time configured in Settings. The
Mac must be available in the logged-in user's session; if a scheduled run is
missed, FinTrack can recover it when it runs again. The snapshot is dated as
the previous calendar day, while the Snapshot button records the current day.

## Build from source

Requirements: macOS 14 or later and Swift 6 (Xcode Command Line Tools).

```bash
swift build -c release
```

To package an app bundle and ZIP for Apple Silicon (the default ad-hoc
signature is not an Apple Developer ID signature):

```bash
bash scripts/package-app.sh 0.1.7
```

The app bundle and ZIP are written under `releases/`. See
[`docs/releasing.md`](docs/releasing.md) for signing and release notes.

## Known limitations

- macOS only; the current release artifact supports Apple Silicon only
- The current release has no Apple Developer ID signature, notarization, or
  automatic updater
- Market-data availability depends on external public APIs and supported
  symbols

## Report a problem

If you find a bug or something that is unclear, please [open a GitHub
Issue](https://github.com/chgwyellow/FinTrack/issues/new).

When possible, include:

- The FinTrack version and macOS version
- The page or feature where the problem occurred
- Steps to reproduce the problem
- The expected result and what actually happened
- A screenshot or screen recording, if it helps explain the problem
