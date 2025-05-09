SELECT
  `major_category` AS crime_category,
  SUM(`value`)    AS num_incidents
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE `borough` = 'Barking and Dagenham'
GROUP BY `major_category`
ORDER BY num_incidents DESC
LIMIT 3;