SELECT
    "country_name",
    ROUND(("cumulative_recovered" / "cumulative_confirmed") * 100, 2) AS "recovery_rate_percent"
FROM COVID19_OPEN_DATA.COVID19_OPEN_DATA.COVID19_OPEN_DATA
WHERE "date" = '2020-05-10'
  AND "aggregation_level" = 0                -- country-level rows
  AND "cumulative_confirmed" > 50000         -- more than 50 000 confirmed cases
  AND "cumulative_recovered" IS NOT NULL
ORDER BY "recovery_rate_percent" DESC NULLS LAST
LIMIT 3;