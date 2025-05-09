WITH top_state AS (
  SELECT
    state_name
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND total_assets IS NOT NULL
  GROUP BY
    state_name
  ORDER BY
    SUM(total_assets) DESC
  LIMIT 1
)
SELECT
  t.state_name AS state,
  COUNT(DISTINCT i.fdic_certificate_number) AS total_institutions
FROM
  top_state AS t
JOIN
  `bigquery-public-data.fdic_banks.institutions` AS i
ON
  i.state_name = t.state_name
GROUP BY
  state;