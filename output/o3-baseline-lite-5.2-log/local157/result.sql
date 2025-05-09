WITH parsed AS (
    /* 1. Convert the text “volume” into a numeric value */
    SELECT
        ticker,
        market_date,
        /* put the date in ISO format so it sorts correctly */
        substr(market_date,7,4)||'-'||substr(market_date,4,2)||'-'||substr(market_date,1,2) AS iso_dt,
        CASE
            WHEN volume = '-'                      THEN 0
            WHEN volume LIKE '%K'                  THEN CAST(REPLACE(REPLACE(volume,'K',''),',','') AS REAL) * 1000
            WHEN volume LIKE '%M'                  THEN CAST(REPLACE(REPLACE(volume,'M',''),',','') AS REAL) * 1000000
            ELSE CAST(REPLACE(volume,',','') AS REAL)
        END                                         AS vol_num
    FROM bitcoin_prices
),
aug_window AS (
    /* 2. Keep just 1‑10 Aug 2021 for the rows we must report   */
    SELECT *
    FROM parsed
    WHERE iso_dt BETWEEN '2021-08-01' AND '2021-08-10'
),
prev_vol AS (
    /* 3. For every row (all dates) grab the most‑recent NON‑ZERO
          volume before the current day for that same ticker      */
    SELECT
        p1.ticker,
        p1.iso_dt,
        (
            SELECT p2.vol_num
            FROM parsed AS p2
            WHERE p2.ticker = p1.ticker
              AND p2.iso_dt  < p1.iso_dt
              AND p2.vol_num <> 0
            ORDER BY p2.iso_dt DESC
            LIMIT 1
        ) AS prev_nonzero_vol
    FROM parsed AS p1
)
SELECT
    a.ticker,
    a.market_date,
    a.vol_num                                AS volume,
    pv.prev_nonzero_vol                      AS prev_volume,
    CASE
        WHEN pv.prev_nonzero_vol IS NULL
             THEN NULL
        ELSE ROUND((a.vol_num - pv.prev_nonzero_vol)
                   * 100.0 / pv.prev_nonzero_vol , 4)
    END                                      AS pct_change
FROM       aug_window  AS a
LEFT JOIN  prev_vol    AS pv
       ON  a.ticker   = pv.ticker
       AND a.iso_dt   = pv.iso_dt
ORDER BY   a.ticker,
           a.iso_dt;