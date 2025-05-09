WITH all_years AS (
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2011
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2012
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2013
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2014
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2015
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2016
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2017
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2018
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    UNION ALL
    SELECT "stn","year","mo","da","temp","wdsp","prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2020
)
SELECT
    "year",
    AVG("temp")                                                    AS "avg_temp_f",
    AVG(TRY_TO_DOUBLE("wdsp"))                                     AS "avg_wind_speed_knots",
    AVG(CASE WHEN "prcp" = 99.99 THEN NULL ELSE "prcp" END)        AS "avg_prcp_inches"
FROM all_years
WHERE "stn" = '725030'      -- LaGuardia Airport
  AND "mo"  = '06'          -- June
  AND "da"  = '12'          -- 12th day
GROUP BY "year"
ORDER BY "year";