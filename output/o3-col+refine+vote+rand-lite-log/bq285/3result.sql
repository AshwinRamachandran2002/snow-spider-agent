SELECT
  `zip_code`,
  COUNT(*) AS institutions_in_zip
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  `state` = 'FL'
  AND `zip_code` IS NOT NULL
GROUP BY
  `zip_code`
ORDER BY
  institutions_in_zip DESC
LIMIT
  1;