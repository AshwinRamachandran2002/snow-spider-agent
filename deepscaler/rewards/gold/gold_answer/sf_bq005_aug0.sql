-- Task: Calculate the daily average time interval (in seconds) between consecutive Bitcoin blocks for the year 2023. For each date, compute the average of the time differences between each block and its immediate predecessor by joining the "BLOCKS" table to itself on block numbers where the current block number is one greater than the previous block's number (excluding the genesis block). Include intervals that span across different days (cross-day intervals) when calculating averages. Convert timestamps from microseconds since the Unix epoch to datetime objects and truncate to the date for grouping. Group the results by the date of the current block's timestamp. Order the results by date in ascending order and list the first 10 dates with their average block intervals rounded to 4 decimal places.

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