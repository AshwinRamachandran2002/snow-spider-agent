SELECT COUNT(*) AS "Number_of_Stations"
FROM (
    SELECT t."stn", t."wban"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019" t
    JOIN "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
      ON t."stn" = s."usaf" AND t."wban" = s."wban"
    WHERE t."temp" IS NOT NULL
      AND TO_DATE(s."begin", 'YYYYMMDD') <= TO_DATE('20000101', 'YYYYMMDD')
      AND TO_DATE(s."end", 'YYYYMMDD') >= TO_DATE('20190630', 'YYYYMMDD')
    GROUP BY t."stn", t."wban"
    HAVING COUNT(*) >= 329
)
;