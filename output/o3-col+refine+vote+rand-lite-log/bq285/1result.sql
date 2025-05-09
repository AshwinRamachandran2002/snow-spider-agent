SELECT
  `zip_code`,
  COUNT(DISTINCT `fdic_certificate_number`) AS institution_count
FROM `bigquery-public-data.fdic_banks.locations`
WHERE `state` = 'FL'
GROUP BY `zip_code`
ORDER BY institution_count DESC
LIMIT 1;