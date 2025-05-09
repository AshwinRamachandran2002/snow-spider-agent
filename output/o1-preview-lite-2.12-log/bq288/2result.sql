SELECT COUNT(*) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state_name IS NOT NULL
  AND state_name = (
    SELECT state_name
    FROM (
      SELECT state_name, SUM(total_assets) AS sum_total_assets
      FROM `bigquery-public-data.fdic_banks.institutions`
      WHERE institution_name LIKE 'Bank%'
        AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
        AND state_name IS NOT NULL
        AND total_assets IS NOT NULL
      GROUP BY state_name
      ORDER BY sum_total_assets DESC
      LIMIT 1
    )
  );