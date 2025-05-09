WITH top_state AS (
  SELECT
    state,
    SUM(total_assets) AS total_assets_sum
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE institution_name LIKE 'Bank%'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND total_assets IS NOT NULL
  GROUP BY state
  ORDER BY total_assets_sum DESC
  LIMIT 1
)
SELECT
  ts.state,
  COUNT(*) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions` AS i
JOIN top_state AS ts
ON i.state = ts.state
GROUP BY ts.state;