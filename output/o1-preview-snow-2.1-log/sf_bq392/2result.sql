SELECT TO_DATE(CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0')), 'YYYY-MM-DD') AS "Date",
       TO_CHAR("temp", 'FM9990.0000') AS "Average_Temperature"
FROM "NOAA_GSOD"."NOAA_GSOD"."GSOD2009"
WHERE "stn" = '723758' AND "year" = '2009' AND "mo" = '10'
ORDER BY "Average_Temperature" DESC NULLS LAST
LIMIT 3;