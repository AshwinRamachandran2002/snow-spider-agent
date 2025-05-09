SELECT
  DATE(a.timestamp_of_crash)                                                    AS accident_date,
  CONCAT(
         FORMAT('%.4f', ROUND(a.latitude ,4)), ',',
         FORMAT('%.4f', ROUND(a.longitude,4))
       )                                                                        AS travel_coordinates,
  COALESCE(p.fatalities, 0)                                                     AS fatalities,
  COALESCE(p.injuries  , 0)                                                     AS injuries,
  COALESCE(p.total      , 0)                                                    AS total_casualties,
  a.trafficway_identifier                                                       AS location_description
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
LEFT JOIN (
    SELECT
      consecutive_number,
      SUM(CASE WHEN injury_severity = 4  THEN 1 ELSE 0 END)                    AS fatalities,
      SUM(CASE WHEN injury_severity <> 4 THEN 1 ELSE 0 END)                    AS injuries,
      COUNT(*)                                                                 AS total
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
    GROUP BY consecutive_number
) AS p
USING (consecutive_number)
WHERE a.latitude  NOT IN (77.7777, 88.8888, 99.9999)   -- Sentinel latitude values
  AND a.longitude NOT IN (777.7777, 888.8888, 999.9999); -- Sentinel longitude values