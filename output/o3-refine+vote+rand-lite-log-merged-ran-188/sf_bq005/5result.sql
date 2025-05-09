/*  Daily average Bitcoin block interval (seconds) for year-2023
    – first 10 calendar days, cross-day gaps included (genesis excluded) */
WITH ordered_blocks AS (
    SELECT
        "number",
        TO_TIMESTAMP("timestamp"/1000000)                   AS "ts",
        ROW_NUMBER() OVER (ORDER BY "number")               AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE TO_TIMESTAMP("timestamp"/1000000) >= '2023-01-01'
      AND TO_TIMESTAMP("timestamp"/1000000) <  '2024-01-01'
), gaps AS (
    /* join each block to its immediate predecessor inside 2023 window */
    SELECT
        TO_DATE(curr."ts")                                  AS "block_date",
        DATEDIFF('second', prev."ts", curr."ts")            AS "gap_sec"
    FROM ordered_blocks      curr
    JOIN ordered_blocks      prev
      ON curr.rn = prev.rn + 1
)
SELECT
    "block_date",
    AVG("gap_sec")                                          AS "avg_interval_sec"
FROM gaps
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;