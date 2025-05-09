-- Top 3 warmest dates in October 2009 for station 723758
SELECT
    date_str
FROM (
    SELECT
        TO_CHAR(
            TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0'), 'YYYY-MM-DD'),
            'YYYY-MM-DD'
        ) AS date_str,
        AVG("temp") AS avg_temp
    FROM NOAA_GSOD.NOAA_GSOD.GSOD2009
    WHERE "stn" = '723758'
      AND "year" = '2009'
      AND "mo"   = '10'
      AND "temp" <> 9999.9        -- exclude missing values
    GROUP BY date_str
)
ORDER BY avg_temp DESC NULLS LAST
LIMIT 3;