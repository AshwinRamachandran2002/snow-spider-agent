WITH daily_us AS (
    /* National cumulative totals per day */
    SELECT 
        "date",
        SUM("cumulative_confirmed") AS cumulative_confirmed
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
    GROUP BY "date"
), growth AS (
    /* Daily growth rate = (today – yesterday) / yesterday */
    SELECT
        "date",
        cumulative_confirmed,
        LAG(cumulative_confirmed) OVER (ORDER BY "date") AS prev_confirmed
    FROM daily_us
)
SELECT 
    TO_CHAR("date", 'MM-DD') AS "MM_DD"
FROM growth
WHERE EXTRACT(month FROM "date") IN (3, 4)        -- March or April
  AND prev_confirmed > 0                          -- avoid divide-by-zero / nulls
ORDER BY (cumulative_confirmed - prev_confirmed) / prev_confirmed DESC NULLS LAST
LIMIT 1;