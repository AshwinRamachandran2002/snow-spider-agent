SELECT
  a.geolocation_city AS city_a,
  b.geolocation_city AS city_b,
  (
    (a.avg_latitude - b.avg_latitude)*(a.avg_latitude - b.avg_latitude) +
    (a.avg_longitude - b.avg_longitude)*(a.avg_longitude - b.avg_longitude)
  ) AS distance_squared
FROM (
  SELECT
    geolocation_city,
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS avg_latitude,
    AVG(geolocation_lng) AS avg_longitude
  FROM olist_geolocation
  GROUP BY geolocation_city, geolocation_zip_code_prefix
) a
JOIN (
  SELECT
    geolocation_city,
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS avg_latitude,
    AVG(geolocation_lng) AS avg_longitude
  FROM olist_geolocation
  GROUP BY geolocation_city, geolocation_zip_code_prefix
) b
ON a.geolocation_zip_code_prefix = b.geolocation_zip_code_prefix
  AND a.geolocation_city < b.geolocation_city
ORDER BY distance_squared DESC
LIMIT 1;