/* Daily cumulative smart-contract creations (2017-01-01 – 2021-12-31) */
WITH date_range AS (                       -- every calendar day in the period
    SELECT
        DATEADD(day, SEQ4(), TO_DATE('2017-01-01')) AS "day"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)                -- 1-Jan-2017 through 31-Dec-2021 inclusive
    )
),
eoa_daily AS (                              -- creations by EOAs
    SELECT
        DATE_TRUNC('day',
                   TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                           AS "cnt_eoa"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type"    = 'create'
      AND  "trace_address" IS NULL
      AND  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
            BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP  BY 1
),
contract_daily AS (                         -- creations by contracts
    SELECT
        DATE_TRUNC('day',
                   TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "day",
        COUNT(*)                                           AS "cnt_contract"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE  "trace_type"    = 'create'
      AND  "trace_address" IS NOT NULL
      AND  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
            BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP  BY 1
),
daily_counts AS (                             -- align counts with full calendar
    SELECT
        d."day",
        COALESCE(e."cnt_eoa",      0) AS "cnt_eoa",
        COALESCE(c."cnt_contract", 0) AS "cnt_contract"
    FROM   date_range      d
    LEFT   JOIN eoa_daily       e ON d."day" = e."day"
    LEFT   JOIN contract_daily  c ON d."day" = c."day"
)
SELECT
    "day",
    SUM("cnt_eoa")      OVER (ORDER BY "day") AS "cum_eoa",
    SUM("cnt_contract") OVER (ORDER BY "day") AS "cum_contract"
FROM   daily_counts
ORDER  BY "day";