-- Task: List the number of bank institutions in each zip code in Florida.
SELECT
  `zip_code`,
  COUNT(DISTINCT `fdic_certificate_number`) AS `Number_of_Bank_Institutions`
FROM
  `bigquery-public-data.fdic_banks.locations`
WHERE
  `state` = 'FL'
GROUP BY
  `zip_code`
LIMIT
  100