WITH seq AS (      -- row-number every 2023 Bitcoin block
    SELECT
        "number",
        "timestamp",
        TO_DATE(TO_TIMESTAMP_NTZ("timestamp"/1e6))              AS "block_date",
        ROW_NUMBER() OVER (ORDER BY "number")                   AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("timestamp"/1e6))
          BETWEEN '2023-01-01' AND '2023-12-31'
),
gap AS (           -- seconds to previous block (genesis implicitly excluded)
    SELECT
        s1."block_date",
        (s1."timestamp" - s2."timestamp")/1000000.0            AS interval_sec
    FROM seq s1
    JOIN seq s2
      ON s1.rn = s2.rn + 1
)
SELECT
    "block_date",
    AVG(interval_sec) AS avg_interval_sec
FROM gap
GROUP BY "block_date"
ORDER BY "block_date"
LIMIT 10;