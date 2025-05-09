WITH us_daily AS (
    SELECT
        "date",
        "new_confirmed",
        "cumulative_confirmed",
        /* previous-day cumulative = current cumulative – new cases */
        "new_confirmed" / NULLIF("cumulative_confirmed" - "new_confirmed", 0)  AS growth_rate
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE 
        "country_code" = 'US'
        AND "aggregation_level" = 0           -- national total
        AND MONTH("date") IN (3,4)            -- March or April (any year)
),
ranked AS (
    SELECT
        TO_CHAR("date", 'MM-DD') AS day_mm_dd,
        growth_rate,
        ROW_NUMBER() OVER (ORDER BY growth_rate DESC NULLS LAST) AS rn
    FROM us_daily
    WHERE growth_rate IS NOT NULL
)
SELECT day_mm_dd
FROM ranked
WHERE rn = 1;