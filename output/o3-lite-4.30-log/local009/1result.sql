SELECT ROUND(MAX("aircrafts_data"."range") * 1.0, 4) AS distance_km
FROM   flights
JOIN   aircrafts_data ON aircrafts_data.aircraft_code = flights.aircraft_code
WHERE  flights.departure_airport IN (
           SELECT airport_code
           FROM   airports_data
           WHERE  json_extract(city,'$.en') = 'Abakan'
       )
    OR flights.arrival_airport   IN (
           SELECT airport_code
           FROM   airports_data
           WHERE  json_extract(city,'$.en') = 'Abakan'
       );