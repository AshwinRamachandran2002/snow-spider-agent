SELECT
    DATE_TRUNC('day', DATEADD('second', b1."timestamp" / 1000000, '1970-01-01')) AS "Date",
    ROUND(AVG((b1."timestamp" - b2."timestamp") / 1000000.0), 4) AS "Average_Block_Interval_Seconds"
FROM
    "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS" AS b1
JOIN
    "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS" AS b2 ON b1."number" = b2."number" + 1
WHERE
    b1."timestamp_month" >= '2023-01-01' AND b1."timestamp_month" < '2024-01-01'
GROUP BY
    "Date"
ORDER BY
    "Date" ASC
LIMIT 10;