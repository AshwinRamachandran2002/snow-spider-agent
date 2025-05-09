WITH us_country AS (
    SELECT
        "date",
        "cumulative_confirmed"
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
      AND "aggregation_level" = 0
),
daily_growth AS (
    SELECT
        "date",
        "cumulative_confirmed",
        LAG("cumulative_confirmed") OVER (ORDER BY "date") AS prev_confirmed
    FROM us_country
),
growth_rate AS (
    SELECT
        "date",
        CASE
            WHEN prev_confirmed > 0 THEN 
                 ("cumulative_confirmed" - prev_confirmed) / prev_confirmed
        END AS growth_rate
    FROM daily_growth
    WHERE prev_confirmed IS NOT NULL
),
march_april AS (
    SELECT
        "date",
        growth_rate
    FROM growth_rate
    WHERE TO_CHAR("date", 'MM') IN ('03', '04')
)
SELECT TO_CHAR("date", 'MM-DD') AS "DAY_MM_DD"
FROM march_april
ORDER BY growth_rate DESC NULLS LAST
LIMIT 1;