SELECT EXTRACT(YEAR FROM eventdate) AS year
FROM `bigquery-public-data.gbif.occurrences`
WHERE LOWER(scientificname) LIKE '%sterna paradisaea%'
  AND decimallatitude > 40
  AND month > 1
GROUP BY eventdate
HAVING COUNT(*) > 10
ORDER BY eventdate
LIMIT 1;