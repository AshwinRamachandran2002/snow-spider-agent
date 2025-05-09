/*  Weather stations in Washington (WA) that recorded
    – more than 150 rainy days in 2023, and
    – fewer rainy days in 2023 than in 2022.
    “Rainy day” = PRCP > 0 and PRCP <> 99.99
*/
WITH rd_2023 AS (
    SELECT
        g."stn",
        g."wban",
        COUNT(*)           AS "rainy_days_2023"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
),
rd_2022 AS (
    SELECT
        g."stn",
        g."wban",
        COUNT(*)           AS "rainy_days_2022"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)
SELECT
    r23."stn",
    r23."wban",
    st."name"                     AS "station_name",
    st."lat",
    st."lon",
    r23."rainy_days_2023",
    r22."rainy_days_2022"
FROM rd_2023 r23
JOIN rd_2022 r22
  ON r23."stn"  = r22."stn"
 AND r23."wban" = r22."wban"
JOIN NOAA_DATA.NOAA_GSOD."STATIONS" st
  ON r23."stn"  = st."usaf"
 AND r23."wban" = st."wban"
WHERE r23."rainy_days_2023" > 150
  AND r23."rainy_days_2023" < r22."rainy_days_2022"
ORDER BY r23."rainy_days_2023" DESC NULLS LAST;