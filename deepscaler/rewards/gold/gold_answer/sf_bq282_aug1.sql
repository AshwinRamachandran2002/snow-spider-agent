-- Task: Find the numeric value of the active council district in Austin which has the highest number of bike trips starting in that district.
SELECT s1."council_district"
FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s1
  ON t."start_station_id" = s1."station_id"
WHERE 
  s1."council_district" IS NOT NULL
  AND s1."status" = 'active'
GROUP BY s1."council_district"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1;