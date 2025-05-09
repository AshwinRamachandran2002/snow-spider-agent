SELECT EXTRACT(YEAR FROM MIN(eventdate)) AS year
FROM (
    SELECT eventdate, COUNT(*) AS sightings
    FROM `bigquery-public-data.gbif.occurrences`
    WHERE species = 'Sterna paradisaea' 
      AND decimallatitude > 40 
      AND EXTRACT(MONTH FROM eventdate) > 1
    GROUP BY eventdate
    HAVING COUNT(*) > 10
)