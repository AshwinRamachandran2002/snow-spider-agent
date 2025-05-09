WITH transaction_values AS (
  SELECT
    EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1e6)) AS "year",
    DATE_TRUNC('hour', TO_TIMESTAMP("block_timestamp" / 1e6)) AS "hour",
    TRY_TO_DOUBLE("value") AS "value"
  FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
  WHERE
    "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac' AND
    (
      "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d' OR
      "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
    ) AND
    "block_timestamp" BETWEEN 1546300800000000 AND 1609459199000000
    AND TRY_TO_DOUBLE("value") IS NOT NULL
),
hourly_totals AS (
  SELECT
    "year",
    "hour",
    SUM("value") AS "total_value"
  FROM transaction_values
  GROUP BY "year", "hour"
),
hourly_changes AS (
  SELECT
    "year",
    "hour",
    "total_value",
    "total_value" - LAG("total_value") OVER (PARTITION BY "year" ORDER BY "hour") AS "value_change"
  FROM hourly_totals
),
average_hourly_changes AS (
  SELECT
    "year",
    AVG(ABS("value_change")) AS "average_hourly_change"
  FROM hourly_changes
  WHERE "value_change" IS NOT NULL
  GROUP BY "year"
)
SELECT
  (SELECT "average_hourly_change" FROM average_hourly_changes WHERE "year" = 2020) -
  (SELECT "average_hourly_change" FROM average_hourly_changes WHERE "year" = 2019)
AS "difference_in_average_hourly_change";