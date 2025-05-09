WITH
-- 1. Convert the text date to ISO format and the “volume” text to a pure number
conv AS (
    SELECT
        "ticker",
        DATE(SUBSTR("market_date", 7, 4) || '-' ||
             SUBSTR("market_date", 4, 2) || '-' ||
             SUBSTR("market_date", 1, 2))               AS "mkt_date",
        CASE
            WHEN "volume" = '-'        THEN 0
            WHEN "volume" LIKE '%K'    THEN CAST(REPLACE("volume", 'K', '') AS REAL) * 1000
            WHEN "volume" LIKE '%M'    THEN CAST(REPLACE("volume", 'M', '') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END                                             AS "volume_num"
    FROM "bitcoin_prices"
),

-- 2. Keep only the August-1-to-August-10-2021 window
target AS (
    SELECT *
    FROM conv
    WHERE "mkt_date" BETWEEN '2021-08-01' AND '2021-08-10'
),

-- 3. For every (ticker, date) in that window, find the most-recent *non-zero* prior volume
with_prev AS (
    SELECT
        t."ticker",
        t."mkt_date",
        t."volume_num",
        (
            SELECT c2."volume_num"
            FROM conv AS c2
            WHERE c2."ticker"   = t."ticker"
              AND c2."mkt_date" < t."mkt_date"
              AND c2."volume_num" > 0
            ORDER BY c2."mkt_date" DESC
            LIMIT 1
        )                                               AS "prev_non_zero_vol"
    FROM target AS t
)

-- 4. Final output with percentage change
SELECT
    "ticker",
    "mkt_date"                AS "market_date",
    "volume_num",
    "prev_non_zero_vol",
    CASE
        WHEN "prev_non_zero_vol" IS NULL OR "prev_non_zero_vol" = 0
            THEN NULL
        ELSE ROUND( ( "volume_num" - "prev_non_zero_vol") * 100.0
                     / "prev_non_zero_vol", 2)
    END                         AS "pct_change_vol"
FROM   with_prev
ORDER BY "ticker", "mkt_date";