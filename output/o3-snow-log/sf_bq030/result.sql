WITH country_totals AS (
    SELECT
        "country_region"                                         AS "country",
        SUM("confirmed")                                         AS "total_confirmed",
        SUM(COALESCE("recovered", 0))                            AS "total_recovered"
    FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COMPATIBILITY_VIEW
    WHERE "date" = '2020-05-10'
    GROUP BY "country_region"
),
eligible AS (
    SELECT
        "country",
        "total_confirmed",
        "total_recovered",
        ("total_recovered" / "total_confirmed") * 100            AS "recovery_rate_pct"
    FROM country_totals
    WHERE "total_confirmed" > 50000
)
SELECT
    "country",
    ROUND("recovery_rate_pct", 4) AS "recovery_rate_percentage"
FROM eligible
ORDER BY "recovery_rate_pct" DESC NULLS LAST
LIMIT 3;