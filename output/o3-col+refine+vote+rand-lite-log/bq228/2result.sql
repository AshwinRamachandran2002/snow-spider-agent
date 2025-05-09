SELECT
  `major_category`,
  SUM(`value`) AS total_incidents
FROM
  `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE
  `borough` = 'Barking and Dagenham'
GROUP BY
  `major_category`
ORDER BY
  total_incidents DESC
LIMIT 3;