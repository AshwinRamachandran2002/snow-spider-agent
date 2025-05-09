WITH country_totals AS (
    SELECT
        "country_region"                                             AS country,
        SUM("confirmed")                                             AS total_confirmed,
        SUM("recovered")                                             AS total_recovered
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COMPATIBILITY_VIEW
    WHERE "date" = '2020-05-10'
    GROUP BY "country_region"
)

SELECT
    country,
    ROUND(100 * total_recovered / total_confirmed, 2) AS recovery_rate_percentage
FROM country_totals
WHERE total_confirmed > 50000
      AND total_recovered IS NOT NULL
ORDER BY recovery_rate_percentage DESC NULLS LAST
FETCH 3 ROWS ONLY;