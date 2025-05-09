WITH us_daily AS (
    SELECT
        "date",
        "cumulative_confirmed",
        LAG("cumulative_confirmed") OVER (ORDER BY "date") AS prev_cum
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
      AND "aggregation_level" = 0
      AND "cumulative_confirmed" IS NOT NULL
),
growth AS (
    SELECT
        "date",
        CASE 
            WHEN prev_cum > 0 THEN ("cumulative_confirmed" - prev_cum) / prev_cum
            ELSE NULL
        END AS growth_rate
    FROM us_daily
)
SELECT 
    TO_CHAR("date", 'MM-DD') AS "day"
FROM growth
WHERE MONTH("date") IN (3, 4)
ORDER BY growth_rate DESC NULLS LAST
LIMIT 1;