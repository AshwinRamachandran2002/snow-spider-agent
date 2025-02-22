-- Task: For each day in March and April 2020, list the cumulative confirmed COVID-19 cases in the United States and the previous day's cumulative confirmed cases.
SELECT 
    TO_CHAR("date", 'MM-DD') AS "Date",
    "cumulative_confirmed" AS "Cumulative Confirmed",
    LAG("cumulative_confirmed") OVER (ORDER BY "date") AS "Previous Day Cumulative Confirmed"
FROM "COVID19_OPEN_DATA"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"
WHERE 
    "country_name" = 'United States of America' 
    AND "aggregation_level" = 0 
    AND "date" BETWEEN '2020-03-01' AND '2020-04-30'
ORDER BY "date";