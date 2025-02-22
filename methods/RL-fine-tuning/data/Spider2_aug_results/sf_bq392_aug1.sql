-- Task: List all dates in October 2009 along with their average temperatures for station number 723758, formatted as YYYY-MM-DD.
SELECT
    TO_CHAR(TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0'), 'YYYY-MM-DD'), 'YYYY-MM-DD') AS "Date",
    "temp" AS "Average_Temperature"
FROM NOAA_GSOD.NOAA_GSOD.GSOD2009
WHERE
    "stn" = '723758'
    AND "year" = '2009'
    AND "mo" = '10';