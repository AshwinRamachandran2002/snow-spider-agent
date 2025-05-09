SELECT
    "Date",
    ROUND(AVG("interval_seconds"), 4) AS "Average_Block_Interval_Seconds"
FROM (
    SELECT
        TO_CHAR(DATE_TRUNC('day', TO_TIMESTAMP_LTZ("timestamp" / 1000000)), 'YYYY-MM-DD') AS "Date",
        (("timestamp" - LAG("timestamp") OVER (ORDER BY "timestamp")) / 1000000.0) AS "interval_seconds"
    FROM "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS"
) sub
WHERE "Date" >= '2023-01-01' AND "Date" < '2024-01-01' AND "interval_seconds" IS NOT NULL
GROUP BY "Date"
ORDER BY "Date" ASC
LIMIT 10;