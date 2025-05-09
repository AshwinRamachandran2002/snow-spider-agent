WITH year_values AS (
    SELECT
        "GeoName",
        YEAR("Year") AS "yr",
        "Earnings_per_job_avg"
    FROM SDOH.SDOH_BEA_CAINC30."FIPS"
    WHERE "GeoName" LIKE '%, MA'          -- Massachusetts counties
      AND YEAR("Year") IN (2012, 2017)    -- keep only 2012 and 2017
), pivoted AS (
    SELECT
        "GeoName",
        MAX(CASE WHEN "yr" = 2012 THEN "Earnings_per_job_avg" END) AS "earn_2012",
        MAX(CASE WHEN "yr" = 2017 THEN "Earnings_per_job_avg" END) AS "earn_2017"
    FROM year_values
    GROUP BY "GeoName"
)
SELECT
    "GeoName",
    "earn_2017" - "earn_2012" AS "increase_amount"
FROM pivoted
WHERE "earn_2012" IS NOT NULL
  AND "earn_2017" IS NOT NULL
ORDER BY "increase_amount" DESC NULLS LAST;