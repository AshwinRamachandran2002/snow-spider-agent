SELECT  ss."council_district"  AS "active_council_district"
FROM    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     t
JOIN    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  ss
          ON t."start_station_id" = ss."station_id"
JOIN    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  es
          ON TRY_TO_NUMBER(t."end_station_id") = es."station_id"
WHERE   ss."council_district" IS NOT NULL
  AND   es."council_district" IS NOT NULL
  AND   ss."council_district" = es."council_district"      -- start & end in same district
  AND   t."start_station_id" <> TRY_TO_NUMBER(t."end_station_id")   -- but different stations
GROUP BY ss."council_district"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;