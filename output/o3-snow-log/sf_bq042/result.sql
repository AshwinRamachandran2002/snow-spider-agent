SELECT
    "year",
    AVG("temp")                                                     AS "avg_temp_F",
    AVG(CAST("wdsp" AS FLOAT))                                      AS "avg_wdsp_knots",
    AVG(CASE WHEN "prcp" = 99.99 THEN NULL ELSE "prcp" END)         AS "avg_prcp_in"
FROM (
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2011" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2012" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2013" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2014" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2015" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2016" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2017" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2018" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2019" UNION ALL
    SELECT "year","mo","da","stn","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD."GSOD2020"
) AS all_years
WHERE "stn" = '725030'
  AND "mo"  = '06'
  AND "da"  = '12'
GROUP BY "year"
ORDER BY "year";