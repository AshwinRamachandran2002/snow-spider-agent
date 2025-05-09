-- Total number of all banking institutions in the state
-- that has the highest summed assets among “Bank*” institutions
-- established between 1900-01-01 and 2000-12-31
WITH top_state AS (
  SELECT
    state
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(institution_name) LIKE 'bank%'                       -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'     -- establishment window
  GROUP BY state
  ORDER BY SUM(COALESCE(total_assets, 0)) DESC                     -- highest summed assets
  LIMIT 1                                                          -- keep the top state
)

SELECT
  COUNT(*) AS total_institutions_in_target_state
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM top_state);