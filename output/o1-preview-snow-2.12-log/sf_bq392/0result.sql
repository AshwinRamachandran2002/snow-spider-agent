SELECT
    TO_CHAR(TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0'), 'YYYY-MM-DD'), 'YYYY-MM-DD') AS "Date",
    "temp" AS "Average_Temperature"
FROM NOAA_GSOD.NOAA_GSOD.GSOD2009
WHERE
    "stn" = '723758'
    AND "year" = '2009'
    AND "mo" = '10'
ORDER BY "temp" DESC NULLS LAST, "da" ASC
LIMIT 3;