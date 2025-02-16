-- Task: Calculate the time differences (in seconds) between consecutive Bitcoin blocks in 2023 by joining consecutive blocks via row-numbered self-joins, excluding the genesis block, and list the first 100 intervals.
SELECT
    b1."number" AS "Block_Number",
    (b1."timestamp" - b2."timestamp") / 1000000.0 AS "Block_Interval_Seconds"
FROM
    "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS" AS b1
JOIN
    "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS" AS b2 ON b1."number" = b2."number" + 1
WHERE
    b1."timestamp_month" >= '2023-01-01' AND b1."timestamp_month" < '2024-01-01'
ORDER BY
    b1."number" ASC
LIMIT 100;