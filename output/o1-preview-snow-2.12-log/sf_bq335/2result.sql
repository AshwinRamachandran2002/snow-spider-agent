WITH all_transactions AS (
  SELECT
    f.value::STRING AS "address",
    t."block_timestamp",
    t."value"
  FROM
    "CRYPTO"."CRYPTO_BITCOIN"."INPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
  WHERE
    t."block_timestamp" >= 1506816000000000  -- October 1, 2017 in microseconds
    AND t."block_timestamp" < 1509494400000000  -- November 1, 2017 in microseconds

  UNION ALL

  SELECT
    f.value::STRING AS "address",
    t."block_timestamp",
    t."value"
  FROM
    "CRYPTO"."CRYPTO_BITCOIN"."OUTPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
  WHERE
    t."block_timestamp" >= 1506816000000000
    AND t."block_timestamp" < 1509494400000000
),
address_stats AS (
  SELECT
    "address",
    MAX("block_timestamp") AS "last_transaction_timestamp",
    SUM("value") AS "total_transaction_value"
  FROM
    all_transactions
  GROUP BY
    "address"
),
latest_timestamp AS (
  SELECT
    MAX("last_transaction_timestamp") AS "latest_timestamp"
  FROM
    address_stats
),
latest_addresses AS (
  SELECT
    a."address",
    a."last_transaction_timestamp",
    a."total_transaction_value"
  FROM
    address_stats a
  JOIN
    latest_timestamp lt
    ON a."last_transaction_timestamp" = lt."latest_timestamp"
)
SELECT
  la."address",
  TO_DATE(TO_TIMESTAMP_NTZ(la."last_transaction_timestamp" / 1000000)) AS "last_transaction_date",
  TO_DECIMAL(la."total_transaction_value", 38, 4) AS "total_transaction_value"
FROM
  latest_addresses la
ORDER BY
  la."total_transaction_value" DESC NULLS LAST
LIMIT 1;