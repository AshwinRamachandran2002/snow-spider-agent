SELECT
  `zip_code`,
  COUNT(DISTINCT `fdic_certificate_number`) AS institution_count
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  `state` = 'FL'                  -- Florida only
  AND TRIM(COALESCE(`zip_code`, '')) <> ''   -- exclude blank / NULL ZIPs
GROUP BY
  `zip_code`
ORDER BY
  institution_count DESC
LIMIT 1;