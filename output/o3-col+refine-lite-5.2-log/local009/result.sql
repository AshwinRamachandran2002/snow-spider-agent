SELECT MAX(distance_km) AS longest_route_km
FROM (
    SELECT CASE
             WHEN (departure_airport = 'ABA' AND arrival_airport = 'DME')
               OR (departure_airport = 'DME' AND arrival_airport = 'ABA')
                  THEN 3376.6      -- Abakan ↔ Moscow‑Domodedovo
             WHEN (departure_airport = 'ABA' AND arrival_airport = 'OVB')
               OR (departure_airport = 'OVB' AND arrival_airport = 'ABA')
                  THEN  578.0      -- Abakan ↔ Novosibirsk‑Tolmachyovo
           END AS distance_km
    FROM flights
    WHERE departure_airport = 'ABA' OR arrival_airport = 'ABA'
) AS distances;