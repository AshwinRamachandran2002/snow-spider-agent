SELECT MAX(ad.range) AS longest_route_km
FROM   flights        AS f
JOIN   aircrafts_data AS ad   ON ad.aircraft_code = f.aircraft_code
JOIN   airports_data  AS dep  ON dep.airport_code = f.departure_airport
JOIN   airports_data  AS arr  ON arr.airport_code = f.arrival_airport
WHERE  json_extract(dep.city,'$.en') = 'Abakan'
   OR  json_extract(arr.city,'$.en') = 'Abakan';