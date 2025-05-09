WITH
  base_data AS (
    SELECT
      "ticker",
      TO_DATE("market_date", 'DD-MM-YYYY') AS "market_date",
      CASE
        WHEN TRIM("volume") = '-' THEN 0
        WHEN UPPER(TRIM("volume")) LIKE '%K' THEN
          TRY_TO_NUMBER(REPLACE(LEFT(TRIM("volume"), LENGTH(TRIM("volume")) - 1), ',', '')) * 1000
        WHEN UPPER(TRIM("volume")) LIKE '%M' THEN
          TRY_TO_NUMBER(REPLACE(LEFT(TRIM("volume"), LENGTH(TRIM("volume")) - 1), ',', '')) * 1000000
        ELSE
          TRY_TO_NUMBER(REPLACE(TRIM("volume"), ',', ''))
      END AS volume_numeric
    FROM
      "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES"
    WHERE
      TO_DATE("market_date", 'DD-MM-YYYY') BETWEEN TO_DATE('31-07-2021', 'DD-MM-YYYY') AND TO_DATE('10-08-2021', 'DD-MM-YYYY')
  ),
  base_with_prev AS (
    SELECT
      *,
      NULLIF(volume_numeric, 0) AS volume_numeric_non_zero
    FROM
      base_data
  ),
  volume_with_prev AS (
    SELECT
      *,
      LAST_VALUE(volume_numeric_non_zero) IGNORE NULLS OVER (
        PARTITION BY "ticker"
        ORDER BY "market_date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ) AS prev_volume_numeric_nonzero
    FROM
      base_with_prev
  )
SELECT
  "ticker",
  "market_date",
  ROUND(((volume_numeric - prev_volume_numeric_nonzero) / prev_volume_numeric_nonzero) * 100, 4) AS percentage_volume_change
FROM
  volume_with_prev
WHERE
  "market_date" BETWEEN TO_DATE('01-08-2021', 'DD-MM-YYYY') AND TO_DATE('10-08-2021', 'DD-MM-YYYY')
  AND prev_volume_numeric_nonzero IS NOT NULL
ORDER BY
  "ticker",
  "market_date";