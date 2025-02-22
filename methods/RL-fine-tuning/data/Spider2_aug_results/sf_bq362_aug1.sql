-- Task: Find the total number of trips for each company for each month in 2018, displaying the first 100 results.

SELECT
  "company",
  EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("trip_start_timestamp" / 1000000)) AS "Month",
  COUNT("unique_key") AS "trip_count"
FROM
  CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
WHERE
  EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("trip_start_timestamp" / 1000000)) = 2018
  AND "company" IS NOT NULL
  AND TRIM("company") != ''
GROUP BY
  "company", "Month"
ORDER BY
  "company", "Month"
LIMIT 100;