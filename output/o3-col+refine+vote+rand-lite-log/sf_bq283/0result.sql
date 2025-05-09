-- Top-15 (incl. ties) active stations by trip starts
SELECT
       "station_id",
       "trip_starts",
       "pct_of_all_active_starts",
       "avg_duration_min"
FROM (
        SELECT
               st."station_id",
               COUNT(*)                                       AS "trip_starts",
               100.0 * COUNT(*) /
               SUM(COUNT(*)) OVER ()                         AS "pct_of_all_active_starts",
               AVG(tr."duration_minutes")                    AS "avg_duration_min",
               RANK() OVER (ORDER BY COUNT(*) DESC)          AS "rk"
        FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS     tr
        JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  st
          ON tr."start_station_id" = st."station_id"
        WHERE st."status" = 'active'
        GROUP BY st."station_id"
     ) ranked
WHERE "rk" <= 15
ORDER BY "rk";