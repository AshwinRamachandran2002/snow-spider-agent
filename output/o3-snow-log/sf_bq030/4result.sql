WITH country_totals AS (
    SELECT
        "country_region"                       AS "country",
        SUM(COALESCE("confirmed", 0))  AS "confirmed",
        SUM(COALESCE("recovered", 0))  AS "recovered"
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA."COMPATIBILITY_VIEW"
    WHERE TO_DATE("date") = '2020-05-10'
    GROUP BY "country_region"
),
eligible_countries AS (
    SELECT
        "country",
        "confirmed",
        "recovered",
        ("recovered" / "confirmed") * 100     AS "recovery_rate_pct"
    FROM country_totals
    WHERE "confirmed" > 50000        -- only countries with > 50,000 confirmed cases
)
SELECT
    "country",
    ROUND("recovery_rate_pct", 4)     AS "recovery_rate_percentage"
FROM eligible_countries
ORDER BY "recovery_rate_pct" DESC NULLS LAST
LIMIT 3;