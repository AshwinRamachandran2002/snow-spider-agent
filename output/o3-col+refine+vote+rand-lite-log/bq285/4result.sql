SELECT
  `zip_code`
FROM (
  SELECT
    `zip_code`,
    COUNT(DISTINCT `fdic_certificate_number`) AS institution_cnt,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT `fdic_certificate_number`) DESC) AS rnk
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE `state` = 'FL'
  GROUP BY `zip_code`
)
WHERE rnk = 1;