SELECT 
  ROUND(
    (
      (
        SELECT COUNT(*) 
        FROM (
          SELECT "stn"
          FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
          GROUP BY "stn"
          HAVING COUNT("temp") >= 329
        ) AS "stations_with_90_percent_data"
      )::FLOAT 
      / 
      (
        SELECT COUNT(DISTINCT "stn") 
        FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
      )
    ) * 100, 4
  ) AS "Percentage_of_Stations";