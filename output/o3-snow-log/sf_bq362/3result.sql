WITH trips_2018 AS (   -- keep only 2018 trips and get month bucket
    SELECT 
        "company",
        DATE_TRUNC('month', TO_TIMESTAMP("trip_start_timestamp" / 1000000)) AS month_start
    FROM CHICAGO.CHICAGO_TAXI_TRIPS.TAXI_TRIPS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("trip_start_timestamp" / 1000000)) = 2018
), 
monthly_counts AS (     -- number of trips per company-month
    SELECT
        "company",
        month_start,
        COUNT(*) AS trips
    FROM trips_2018
    GROUP BY
        "company",
        month_start
), 
month_over_month AS (   -- change vs. previous month for each company
    SELECT
        "company",
        month_start,
        trips,
        trips 
          - LAG(trips) OVER (PARTITION BY "company" ORDER BY month_start) AS trip_change
    FROM monthly_counts
), 
max_increase AS (       -- greatest positive change in 2018 for each company
    SELECT
        "company",
        MAX(CASE WHEN trip_change > 0 THEN trip_change ELSE 0 END) AS max_monthly_increase
    FROM month_over_month
    GROUP BY "company"
)
SELECT
    "company",
    max_monthly_increase
FROM max_increase
ORDER BY
    max_monthly_increase DESC NULLS LAST
LIMIT 3;