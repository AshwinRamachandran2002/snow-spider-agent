SELECT `year`, SUM(`value`) AS `Total_Incidents`
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE `borough` = 'Westminster'
  AND `major_category` = 'Theft and Handling'
  AND `minor_category` = 'Other Theft'
GROUP BY `year`
ORDER BY `year`;