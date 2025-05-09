WITH bank_assets_by_state AS (
  SELECT
    state,
    SUM(IFNULL(total_assets,0)) AS total_assets
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'                                  -- names starting with 'Bank'
    AND established_date BETWEEN DATE '1900-01-01' AND DATE '2000-12-31'  -- established within range
  GROUP BY
    state
),
top_state AS (                   -- state with the highest summed assets
  SELECT state
  FROM bank_assets_by_state
  ORDER BY total_assets DESC, state
  LIMIT 1
)
SELECT
  i.state                       AS state,
  COUNT(DISTINCT i.fdic_certificate_number) AS total_institutions
FROM
  `bigquery-public-data.fdic_banks.institutions` AS i
JOIN
  top_state AS t
ON
  i.state = t.state
GROUP BY
  state