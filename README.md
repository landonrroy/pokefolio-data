# pokefolio-data

Daily mirror of Pokémon TCG market prices, powering [PokeFolio](https://github.com/landonroy/PokeFolio).

A GitHub Action runs every day at 21:30 UTC, downloads that day's price dump from
[tcgcsv.com](https://tcgcsv.com) (which republishes TCGplayer's daily prices), keeps only the
Pokémon categories, and commits the result here. A one-time backfill workflow fills in history
from tcgcsv's archive, which goes back to 2024-02-08.

## Layout

```
data/
  2024/prices-2024-02-08.tar.gz
  ...
  2026/prices-2026-07-01.tar.gz
scripts/fetch-day.sh          # fetch + filter + repack one day (used by both workflows)
.github/workflows/
  daily-archive.yml           # cron: today's prices (self-heals up to 7 missed days)
  backfill.yml                # manual: fetch a historical date range
```

Each `prices-YYYY-MM-DD.tar.gz` contains the **raw, unmodified** per-group JSON from tcgcsv:

```
YYYY-MM-DD/{categoryId}/{groupId}/prices
```

- Category `3` = Pokémon (English). Category `85` = Pokémon Japan (absent upstream before mid-2024).
- Each `prices` file: `{ results: [{ productId, lowPrice, midPrice, highPrice, marketPrice, directLowPrice, subTypeName }] }`
- `subTypeName` distinguishes Normal vs Holofoil / Reverse Holofoil rows for the same product.
- ~1 MB per day compressed (~12 MB raw). No transformation is done here on purpose — this repo
  is the immutable source of truth; all parsing/ingestion happens downstream in PokeFolio.

## Operations

- **Backfill:** Actions tab → "Backfill history" → Run workflow (defaults fetch everything).
  Takes roughly an hour; commits progress every 50 days, so it's safe to re-run — already-archived
  days are skipped.
- **Missed days:** the daily job re-checks the last 7 days, so outages self-heal. It fails loudly
  (red run) only if the last 3 days are all missing upstream.
- Prices credit: [TCGplayer](https://www.tcgplayer.com), via tcgcsv.com's free daily dumps.
