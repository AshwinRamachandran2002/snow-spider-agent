WITH ranked AS (
    -- keep December 31 2022 so the first 2023 interval is complete
    SELECT
        "number",
        "timestamp",
        ROW_NUMBER() OVER (ORDER BY "number") AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE "timestamp" >= 1672358400000000          -- 2022-12-31 00:00:00 UTC
),
paired AS (
    -- consecutive-block pairs and raw interval (exclude genesis)
    SELECT
        cur."timestamp" AS cur_ts,
        nxt."timestamp" AS nxt_ts
    FROM ranked cur
    JOIN ranked  nxt
      ON nxt.rn = cur.rn + 1
    WHERE cur."number" <> 0                       -- drop block #0
)
SELECT
    DATE_TRUNC('day', TO_TIMESTAMP(cur_ts/1e6))           AS "block_date",
    AVG( (nxt_ts - cur_ts)/1e6 )                          AS "avg_interval_sec"
FROM   paired
WHERE  cur_ts >= 1672444800000000                         -- from 2023-01-01
GROUP BY 1
ORDER BY 1
LIMIT 10;