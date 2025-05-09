-- 1) Find the state whose “Bank …” institutions (established 1900-2000) have the
--    largest summed assets.
-- 2) Count ALL banking institutions located in that top-asset state.
WITH bank_1900_2000 AS (
  SELECT
    `state`,
    SUM(COALESCE(`total_assets`, 0)) AS state_asset_sum
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(`institution_name`) LIKE 'bank%'
        AND `established_date` BETWEEN '1900-01-01' AND '2000-12-31'
  GROUP BY `state`
),
top_state AS (
  SELECT `state`
  FROM bank_1900_2000
  ORDER BY state_asset_sum DESC
  LIMIT 1          -- the state with the highest summed assets
)
SELECT
  COUNT(DISTINCT `fdic_certificate_number`) AS all_institution_count
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE `state` IN (SELECT `state` FROM top_state);