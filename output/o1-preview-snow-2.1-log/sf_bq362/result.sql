WITH monthly_counts AS (
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
)
SELECT
  m1."company" AS "Company",
  m1."Month" AS "Month_Start",
  m2."Month" AS "Month_End",
  m2."trip_count" - m1."trip_count" AS "Increase_in_Trip_Numbers"
FROM
  monthly_counts m1
  JOIN monthly_counts m2 ON m1."company" = m2."company" AND m2."Month" = m1."Month" + 1
WHERE
  m2."trip_count" - m1."trip_count" > 0
ORDER BY
  (m2."trip_count" - m1."trip_count") DESC NULLS LAST
LIMIT 3;