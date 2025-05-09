WITH cleaned AS (
    /* convert the textual volume field to a real number               */
    /* - volumes ending in K → thousands, ending in M → millions       */
    /* - a single “-” means zero                                       */
    /* also re‑format the market_date so it can be compared as a date  */
    SELECT
        ticker,
        market_date,                                            -- original text date (dd‑mm‑yyyy)
        substr(market_date,7,4) || '-' ||                       -- yyyy
        substr(market_date,4,2) || '-' ||                       -- mm
        substr(market_date,1,2)              AS date_iso,       -- dd  → yyyy‑mm‑dd
        CASE
            WHEN volume = '-'              THEN 0
            WHEN volume LIKE '%K'          THEN CAST(REPLACE(volume,'K','') AS REAL) * 1000
            WHEN volume LIKE '%M'          THEN CAST(REPLACE(volume,'M','') AS REAL) * 1000000
            ELSE CAST(volume AS REAL)
        END                                 AS volume_num
    FROM bitcoin_prices
),
range_dates AS (
    /* keep only the dates we need: 1–10 Aug 2021 (inclusive) */
    SELECT *
    FROM   cleaned
    WHERE  date_iso BETWEEN '2021-08-01' AND '2021-08-10'
)

SELECT
    r.ticker,
    r.market_date,
    ROUND(
          (r.volume_num - (
               /* most recent earlier NON‑ZERO volume for the same ticker */
               SELECT c2.volume_num
               FROM   cleaned c2
               WHERE  c2.ticker   = r.ticker
               AND    c2.date_iso < r.date_iso
               AND    c2.volume_num > 0
               ORDER  BY c2.date_iso DESC
               LIMIT 1
          ))
          * 100.0
          / (
               SELECT c2.volume_num
               FROM   cleaned c2
               WHERE  c2.ticker   = r.ticker
               AND    c2.date_iso < r.date_iso
               AND    c2.volume_num > 0
               ORDER  BY c2.date_iso DESC
               LIMIT 1
          )
    , 4)  AS pct_change_volume
FROM   range_dates r
ORDER  BY r.ticker,
          r.date_iso;