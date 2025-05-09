WITH hourly_changes AS (
  SELECT
    YEAR,
    "hour",
    "total_value",
    LAG("total_value") OVER (PARTITION BY YEAR ORDER BY "hour") AS "previous_total_value",
    ABS("total_value" - LAG("total_value") OVER (PARTITION BY YEAR ORDER BY "hour")) AS "value_change"
  FROM (
    SELECT
      CASE
        WHEN "block_timestamp" >= 1546300800000000 AND "block_timestamp" < 1577836800000000 THEN 2019
        WHEN "block_timestamp" >= 1577836800000000 AND "block_timestamp" < 1609459200000000 THEN 2020
      END AS YEAR,
      DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "hour",
      SUM(CAST("value" AS FLOAT)) AS "total_value"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
        "from_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', '0xfbd6c6b112214d949dcdfb1217153bc0a742862f') OR
        "to_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      )
      AND "block_timestamp" >= 1546300800000000
      AND "block_timestamp" < 1609459200000000
    GROUP BY YEAR, "hour"
    HAVING YEAR IS NOT NULL
  ) t
)
SELECT
  (AVG(CASE WHEN YEAR = 2020 THEN "value_change" END) - AVG(CASE WHEN YEAR = 2019 THEN "value_change" END)) AS difference
FROM hourly_changes
WHERE "value_change" IS NOT NULL;