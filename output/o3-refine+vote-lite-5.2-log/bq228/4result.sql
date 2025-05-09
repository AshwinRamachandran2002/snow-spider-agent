SELECT
  `major_category`,
  SUM(`value`) AS incident_count
FROM
  `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE
  `borough` = 'Barking and Dagenham'
GROUP BY
  `major_category`
ORDER BY
  incident_count DESC
LIMIT 3;