/*  Weather stations in Washington (WA) that
    • had more than 150 “rainy days” in 2023
    • but fewer rainy days in 2023 than in 2022
    (“rainy day” = PRCP > 0 AND PRCP <> 99.99)                                  */

WITH rd_2023 AS (   -- count 2023 rainy days
    SELECT
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_days_2023"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023"  AS g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  AS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99          -- exclude missing / trace values
      AND g."prcp"  > 0              -- precipitation actually occurred
    GROUP BY g."stn", g."wban"
),
rd_2022 AS (   -- count 2022 rainy days
    SELECT
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_days_2022"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"  AS g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  AS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)

SELECT
    s."name"               AS "station_name",
    s."usaf"               AS "stn",
    s."wban",
    rd_2023."rainy_days_2023",
    rd_2022."rainy_days_2022"
FROM rd_2023
JOIN rd_2022
  ON rd_2023."stn"  = rd_2022."stn"
 AND rd_2023."wban" = rd_2022."wban"
JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  AS s
  ON rd_2023."stn"  = s."usaf"
 AND rd_2023."wban" = s."wban"
WHERE rd_2023."rainy_days_2023" > 150            -- >150 rainy days in 2023
  AND rd_2023."rainy_days_2023" < rd_2022."rainy_days_2022"  -- but fewer than 2022
ORDER BY rd_2023."rainy_days_2023" DESC NULLS LAST;