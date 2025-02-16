-- Task: Find the date between March 1, 2020, and April 30, 2020, in the United States where the ratio of new confirmed COVID-19 cases to the cumulative confirmed cases up to the previous day was the highest. Return the date in MM-DD format.

WITH us_data AS (
    SELECT 
        "date", 
        "new_confirmed", 
        "cumulative_confirmed",
        LAG("cumulative_confirmed") OVER (ORDER BY "date") AS prev_cumulative_confirmed
    FROM "COVID19_OPEN_DATA"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"
    WHERE 
        "country_name" = 'United States of America' 
        AND "aggregation_level" = 0 
        AND "date" BETWEEN '2020-03-01' AND '2020-04-30'
),
growth_rates AS (
    SELECT 
        "date", 
        "new_confirmed", 
        "cumulative_confirmed",
        prev_cumulative_confirmed,
        CASE 
            WHEN prev_cumulative_confirmed = 0 OR prev_cumulative_confirmed IS NULL THEN NULL
            ELSE ROUND("new_confirmed" / prev_cumulative_confirmed, 4)
        END AS growth_rate
    FROM us_data
)
SELECT 
    TO_CHAR("date", 'MM-DD') AS "Date"
FROM growth_rates
ORDER BY growth_rate DESC NULLS LAST
LIMIT 1;