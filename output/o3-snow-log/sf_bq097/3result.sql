SELECT
    "GeoName",
    MAX(CASE WHEN "Year" = DATE '2012-01-01' THEN "Earnings_per_job_avg" END) AS "Avg_Earnings_2012",
    MAX(CASE WHEN "Year" = DATE '2017-01-01' THEN "Earnings_per_job_avg" END) AS "Avg_Earnings_2017",
    MAX(CASE WHEN "Year" = DATE '2017-01-01' THEN "Earnings_per_job_avg" END)
      - MAX(CASE WHEN "Year" = DATE '2012-01-01' THEN "Earnings_per_job_avg" END) AS "Increase_2012_to_2017"
FROM
    SDOH.SDOH_BEA_CAINC30.FIPS
WHERE
    "GeoName" LIKE '%, MA'                -- only Massachusetts geographies
    AND "Year" IN (DATE '2012-01-01', DATE '2017-01-01')
GROUP BY
    "GeoName"
HAVING
    MAX(CASE WHEN "Year" = DATE '2012-01-01' THEN "Earnings_per_job_avg" END) IS NOT NULL
    AND MAX(CASE WHEN "Year" = DATE '2017-01-01' THEN "Earnings_per_job_avg" END) IS NOT NULL
ORDER BY
    "Increase_2012_to_2017" DESC NULLS LAST;