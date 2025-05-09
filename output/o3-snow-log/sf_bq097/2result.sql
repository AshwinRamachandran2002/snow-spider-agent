SELECT
    y2012."GeoName",
    y2012."Earnings_per_job_avg"  AS "Earnings_2012",
    y2017."Earnings_per_job_avg"  AS "Earnings_2017",
    (y2017."Earnings_per_job_avg" - y2012."Earnings_per_job_avg") AS "Increase_amount"
FROM
    ( SELECT "GeoName", "Earnings_per_job_avg"
      FROM SDOH.SDOH_BEA_CAINC30.FIPS
      WHERE "Year" = '2012-01-01'
        AND "GeoName" LIKE '%, MA'
    ) y2012
JOIN
    ( SELECT "GeoName", "Earnings_per_job_avg"
      FROM SDOH.SDOH_BEA_CAINC30.FIPS
      WHERE "Year" = '2017-01-01'
        AND "GeoName" LIKE '%, MA'
    ) y2017
  ON y2012."GeoName" = y2017."GeoName"
ORDER BY
    "Increase_amount" DESC NULLS LAST;