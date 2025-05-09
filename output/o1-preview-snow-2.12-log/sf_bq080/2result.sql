WITH dates AS (
  SELECT
    DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2018-08-30'::DATE) AS "date"
  FROM
    TABLE(GENERATOR(ROWCOUNT => 32))
),
all_contracts AS (
  SELECT DISTINCT
    t."to_address" AS "contract_address"
  FROM
    CRYPTO.CRYPTO_ETHEREUM.TRACES t
  WHERE
    t."trace_type" = 'create'
    AND t."block_timestamp" < 1538352000000000  -- Up to September 30, 2018
),
contract_creations AS (
  SELECT
    DATE_TRUNC('day', TO_TIMESTAMP_LTZ(t."block_timestamp" / 1e6)) AS "date",
    CASE WHEN ac."contract_address" IS NULL THEN 'User_Created' ELSE 'Contract_Created' END AS "creator_type"
  FROM
    CRYPTO.CRYPTO_ETHEREUM.TRACES t
  LEFT JOIN
    all_contracts ac
  ON
    t."from_address" = ac."contract_address"
  WHERE
    t."trace_type" = 'create'
    AND t."block_timestamp" >= 1535587200000000  -- August 30, 2018
    AND t."block_timestamp" <= 1538351999000000  -- September 30, 2018
),
daily_counts AS (
  SELECT
    "date",
    "creator_type",
    COUNT(*) AS "daily_count"
  FROM
    contract_creations
  GROUP BY
    "date", "creator_type"
),
daily_totals AS (
  SELECT
    d."date",
    COALESCE(SUM(CASE WHEN dc."creator_type" = 'User_Created' THEN dc."daily_count" END), 0) AS "daily_user_created",
    COALESCE(SUM(CASE WHEN dc."creator_type" = 'Contract_Created' THEN dc."daily_count" END), 0) AS "daily_contract_created"
  FROM
    dates d
  LEFT JOIN
    daily_counts dc
  ON
    d."date" = dc."date"
  GROUP BY
    d."date"
  ORDER BY
    d."date"
)
SELECT
  TO_CHAR(dt."date", 'YYYY-MM-DD') AS "Date",
  SUM(dt."daily_user_created") OVER (ORDER BY dt."date" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Cumulative_User_Created_Contracts",
  SUM(dt."daily_contract_created") OVER (ORDER BY dt."date" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Cumulative_Contract_Created_Contracts"
FROM
  daily_totals dt
ORDER BY
  dt."date";