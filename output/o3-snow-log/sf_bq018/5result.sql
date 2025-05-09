WITH us_daily AS (
    SELECT 
        "date",
        SUM("cumulative_confirmed") AS cum_confirmed
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
    GROUP BY "date"
), growth_calc AS (
    SELECT
        "date",
        cum_confirmed,
        LAG(cum_confirmed) OVER (ORDER BY "date") AS prev_cum_confirmed
    FROM us_daily
), growth_rate AS (
    SELECT
        "date",
        (cum_confirmed - prev_cum_confirmed) / prev_cum_confirmed AS growth_rate
    FROM growth_calc
    WHERE 
        prev_cum_confirmed > 0
        AND TO_CHAR("date", 'MM') IN ('03', '04')         -- March or April (any year)
)
SELECT 
    TO_CHAR("date", 'MM-DD') AS "DAY_IN_MONTH"
FROM growth_rate
ORDER BY growth_rate DESC NULLS LAST
LIMIT 1;