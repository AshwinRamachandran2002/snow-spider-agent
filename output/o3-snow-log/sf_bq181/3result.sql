WITH station_days AS (
    SELECT
        "stn",
        COUNT(*)                                                        AS "total_days",
        SUM(
            CASE 
                WHEN  "temp" IS NOT NULL AND "temp" <> 9999.9
                  AND "max"  IS NOT NULL AND "max"  <> 9999.9
                  AND "min"  IS NOT NULL AND "min"  <> 9999.9
                THEN 1 ELSE 0 
            END
        )                                                              AS "valid_days"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"
    WHERE "year" = '2022'                 -- ensure we are only counting 2022 rows
      AND "stn" <> '999999'               -- exclude invalid USAF identifiers
    GROUP BY "stn"
),
counts AS (
    SELECT
        COUNT(*)                                                          AS "total_stations",
        SUM(CASE WHEN "valid_days" >= 0.9 * 365 THEN 1 ELSE 0 END)        AS "qualified_stations"
    FROM station_days
)
SELECT
    ROUND("qualified_stations" * 100.0 / NULLIF("total_stations", 0), 2)  AS "PERCENTAGE_VALID_STATIONS_2022"
FROM counts;