/* ---------------------------------------------------------------
   Annual precipitation percentile for every U.S. GSOD station
   across the complete record (1929-2024).
   – annual_prcp_in         : yearly precipitation total (inches)
   – annual_prcp_percentile : PERCENT_RANK of that total among all
                              U.S. stations for the same year
-----------------------------------------------------------------*/
WITH us_stations AS (                    -- U.S. station identifiers
    SELECT "usaf" AS "stn"
    FROM   "NOAA_DATA"."NOAA_GSOD"."STATIONS"
    WHERE  "country" = 'US'
),

/* ----------------------------------------------------------------
   1)  Concatenate ALL daily GSOD tables, keep only needed columns,
       discard the 99.99 “missing precip” flag.
-----------------------------------------------------------------*/
daily_raw AS (
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1929" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1930" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1931" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1932" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1933" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1934" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1935" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1936" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1937" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1938" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1939" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1940" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1941" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1942" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1943" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1944" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1945" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1946" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1947" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1948" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1949" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1950" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1951" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1952" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1953" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1954" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1955" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1956" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1957" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1958" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1959" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1960" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1961" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1962" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1963" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1964" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1965" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1966" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1967" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1968" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1969" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1970" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1971" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1972" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1973" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1974" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1975" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1976" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1977" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1978" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1979" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1980" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1981" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1982" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1983" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1984" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1985" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1986" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1987" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1988" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1989" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1990" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1991" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1992" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1993" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1994" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1995" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1996" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1997" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1998" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD1999" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2000" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2001" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2002" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2003" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2004" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2005" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2006" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2007" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2008" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2009" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2010" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2011" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2012" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2013" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2014" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2015" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2016" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2017" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2018" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2020" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2021" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2023" WHERE "prcp" < 99.99 UNION ALL
    SELECT "stn","year","prcp" FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2024" WHERE "prcp" < 99.99
),

/* ----------------------------------------------------------------
   2)  Keep only U.S. stations (join after the UNION to avoid the
       “ambiguous column” error and still cut rows before aggreg.)
-----------------------------------------------------------------*/
all_daily AS (
    SELECT r."stn",
           r."year",
           CAST(r."prcp" AS FLOAT) AS "prcp"
    FROM   daily_raw r
    JOIN   us_stations u
           ON r."stn" = u."stn"
),

/* ----------------------------------------------------------------
   3)  Yearly precipitation totals for every U.S. station
-----------------------------------------------------------------*/
annual_station_totals AS (
    SELECT "stn",
           "year",
           SUM("prcp") AS "annual_prcp_in"
    FROM   all_daily
    GROUP  BY "stn", "year"
)

/* ----------------------------------------------------------------
   4)  Percentile rank of each station’s total within its year
-----------------------------------------------------------------*/
SELECT
    "year",
    "stn",
    ROUND("annual_prcp_in", 2)                                       AS "annual_prcp_in",
    ROUND(
        PERCENT_RANK() OVER (PARTITION BY "year"
                             ORDER BY "annual_prcp_in"),
        4)                                                           AS "annual_prcp_percentile"
FROM   annual_station_totals
ORDER  BY "year", "stn";