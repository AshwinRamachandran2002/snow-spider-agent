SELECT
  DATE_PART('month', TO_TIMESTAMP_NTZ("start_date" / 1e6)) AS "Month_num",
  TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_NTZ("start_date" / 1e6)), 'Month YYYY') AS "Month",
  ROUND(SUM(CASE WHEN "subscriber_type" = 'Customer' THEN "duration_sec" ELSE 0 END) / 60, 4) AS "Cumulative_Usage_Minutes_Customers",
  ROUND(SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" ELSE 0 END) / 60, 4) AS "Cumulative_Usage_Minutes_Subscribers",
  ROUND(
    ABS(
      SUM(CASE WHEN "subscriber_type" = 'Customer' THEN "duration_sec" ELSE 0 END) - 
      SUM(CASE WHEN "subscriber_type" = 'Subscriber' THEN "duration_sec" ELSE 0 END)
    ) / 60, 4
  ) AS "Absolute_Difference"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
WHERE
  DATE_PART('year', TO_TIMESTAMP_NTZ("start_date" / 1e6)) = 2017
  AND "subscriber_type" IN ('Customer', 'Subscriber')
GROUP BY
  "Month_num", "Month"
ORDER BY
  "Absolute_Difference" DESC NULLS LAST,
  "Month_num"
LIMIT 1;