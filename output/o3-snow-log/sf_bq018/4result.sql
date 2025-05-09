WITH daily_us AS (   -- total U.S. numbers for each day in the period
    SELECT
        "date",
        SUM(COALESCE("new_confirmed",0))        AS new_confirmed,
        SUM(COALESCE("cumulative_confirmed",0)) AS cumulative_confirmed
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
      AND "date" BETWEEN '2020-03-01' AND '2020-04-30'
    GROUP BY "date"
), with_prev AS (     -- bring in previous-day cumulative confirmed
    SELECT
        d.*,
        LAG(cumulative_confirmed) OVER (ORDER BY "date") AS prev_cum
    FROM daily_us d
)
SELECT
    TO_CHAR("date",'MM-DD') AS "day_with_max_growth_rate"
FROM with_prev
WHERE prev_cum > 0
ORDER BY (new_confirmed / prev_cum) DESC NULLS LAST
LIMIT 1;