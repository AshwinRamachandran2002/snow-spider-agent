SELECT 
  ROUND(
    (
      (
        SELECT COUNT(*) FROM (
          SELECT "stn", "wban"
          FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
          WHERE "temp" IS NOT NULL
          GROUP BY "stn", "wban"
          HAVING COUNT(DISTINCT TO_DATE(CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0')), 'YYYY-MM-DD')) >= 329
        )
      ) * 100.0
    ) / 
    (
      SELECT COUNT(DISTINCT "stn", "wban")
      FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
    )
  , 4
  ) AS "Percentage_of_Stations";