WITH us_daily AS (
    SELECT
        "date",
        "new_confirmed",
        "cumulative_confirmed"
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
    WHERE "country_code" = 'US'
      AND "aggregation_level" = 0
      AND "new_confirmed" IS NOT NULL
      AND "cumulative_confirmed" IS NOT NULL
      AND EXTRACT(MONTH FROM "date") IN (3, 4)          -- March or April
), growth AS (
    SELECT
        "date",
        "new_confirmed" / NULLIF("cumulative_confirmed" - "new_confirmed", 0) AS growth_rate
    FROM us_daily
)
SELECT TO_CHAR("date", 'MM-DD') AS "MM_DD"
FROM growth
ORDER BY growth_rate DESC NULLS LAST
LIMIT 1;