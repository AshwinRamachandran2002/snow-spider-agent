SELECT
    "GeoName",
    MAX(CASE WHEN "Year" = '2017-01-01' THEN "Earnings_per_job_avg" END) -
    MAX(CASE WHEN "Year" = '2012-01-01' THEN "Earnings_per_job_avg" END) AS "Increase_in_Earnings_per_Job"
FROM
    "SDOH"."SDOH_BEA_CAINC30"."FIPS"
WHERE
    "GeoName" LIKE '%, MA' AND "Year" IN ('2012-01-01', '2017-01-01')
GROUP BY
    "GeoName";