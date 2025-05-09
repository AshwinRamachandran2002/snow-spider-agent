SELECT
    "country_name"                                   AS "country",
    ROUND(("cumulative_recovered" / "cumulative_confirmed") * 100, 4) 
                                                    AS "recovery_rate_percentage"
FROM
    COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
WHERE
    "date" = '2020-05-10'
    AND "aggregation_level" = 1          -- country level
    AND "cumulative_confirmed" > 50000   -- only countries with >50,000 cases
    AND "cumulative_recovered" IS NOT NULL
ORDER BY
    "recovery_rate_percentage" DESC NULLS LAST
LIMIT 3;