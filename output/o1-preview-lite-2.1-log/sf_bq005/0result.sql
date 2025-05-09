WITH blocks_2023 AS (
  SELECT
    "number",
    "timestamp",
    TO_TIMESTAMP_NTZ("timestamp" / 1e6) AS "block_datetime"
  FROM
    "CRYPTO"."CRYPTO_BITCOIN"."BLOCKS"
  WHERE
    EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("timestamp" / 1e6)) = 2023
),
blocks_with_intervals AS (
  SELECT
    "number",
    "timestamp",
    "block_datetime",
    DATE_TRUNC('DAY', "block_datetime") AS "date",
    ("timestamp" - LAG("timestamp") OVER (ORDER BY "timestamp")) / 1e6 AS "block_interval_seconds"
  FROM
    blocks_2023
)
SELECT
  TO_CHAR("date", 'YYYY-MM-DD') AS "Date",
  ROUND(AVG("block_interval_seconds"), 4) AS "Average_Block_Interval_Seconds"
FROM
  blocks_with_intervals
WHERE
  "block_interval_seconds" IS NOT NULL
GROUP BY
  "date"
ORDER BY
  "date"
LIMIT 10;