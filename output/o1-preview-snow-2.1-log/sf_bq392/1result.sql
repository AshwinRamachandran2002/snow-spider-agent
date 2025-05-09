SELECT
  DATE_FROM_PARTS(
    CAST("year" AS INTEGER),
    CAST("mo" AS INTEGER),
    CAST("da" AS INTEGER)
  ) AS "Date",
  ROUND("temp", 4) AS "Average_Temperature"
FROM
  NOAA_GSOD.NOAA_GSOD."GSOD2009"
WHERE
  "stn" = '723758' AND
  "mo" = '10' AND
  "year" = '2009'
ORDER BY
  "Average_Temperature" DESC NULLS LAST,
  "da" ASC
LIMIT 3;