WITH clay_ids AS (
  SELECT SAFE_CAST(stop_id AS INT64) AS stop_id_int
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Clay St & Drumm St'
),
sacramento_ids AS (
  SELECT SAFE_CAST(stop_id AS INT64) AS stop_id_int
  FROM `bigquery-public-data.san_francisco_transit_muni.stops`
  WHERE stop_name = 'Sacramento St & Davis St'
),
trip_pairs AS (
  SELECT
    cl.trip_id,
    cl.departure_time AS clay_departure,
    sa.arrival_time   AS sacramento_arrival
  FROM `bigquery-public-data.san_francisco_transit_muni.stop_times` AS cl
  JOIN `bigquery-public-data.san_francisco_transit_muni.stop_times` AS sa
    ON cl.trip_id = sa.trip_id
  WHERE cl.stop_id IN (SELECT stop_id_int FROM clay_ids)
    AND sa.stop_id IN (SELECT stop_id_int FROM sacramento_ids)
    AND cl.stop_sequence < sa.stop_sequence            -- Clay precedes Sacramento
)
SELECT
  tr.trip_headsign,
  FORMAT_TIME('%H:%M:%S', MIN(clay_departure))     AS earliest_departure_time,
  FORMAT_TIME('%H:%M:%S', MAX(sacramento_arrival)) AS latest_arrival_time
FROM trip_pairs
JOIN `bigquery-public-data.san_francisco_transit_muni.trips` AS tr
  ON trip_pairs.trip_id = SAFE_CAST(tr.trip_id AS INT64)
GROUP BY tr.trip_headsign
ORDER BY tr.trip_headsign;