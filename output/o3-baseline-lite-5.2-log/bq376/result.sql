-- Bike‑share stations and crime incidents per San‑Francisco neighborhood
WITH neighborhoods AS (
  SELECT
    neighborhood,
    neighborhood_geom
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries`
),

/* ----- bike‑share stations inside each neighborhood -------------------- */
station_neigh AS (
  SELECT
    nb.neighborhood,
    COUNT(DISTINCT bs.station_id) AS station_count
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS bs
  JOIN neighborhoods AS nb
  ON ST_WITHIN(
       ST_GEOGPOINT(bs.lon , bs.lat),          -- point for the station
       nb.neighborhood_geom                    -- neighborhood polygon
     )
  WHERE bs.lon IS NOT NULL
    AND bs.lat IS NOT NULL
  GROUP BY nb.neighborhood
),

/* ----- police incidents inside each neighborhood ----------------------- */
incident_neigh AS (
  SELECT
    nb.neighborhood,
    COUNT(DISTINCT si.unique_key) AS incident_count
  FROM `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS si
  JOIN neighborhoods AS nb
  ON ST_WITHIN(
       ST_GEOGPOINT(si.longitude , si.latitude), -- point for the incident
       nb.neighborhood_geom                       -- neighborhood polygon
     )
  WHERE si.longitude IS NOT NULL
    AND si.latitude  IS NOT NULL
  GROUP BY nb.neighborhood
)

/* ----- return neighborhoods that have BOTH a station and an incident --- */
SELECT
  sn.neighborhood,
  sn.station_count,
  inb.incident_count
FROM station_neigh sn
JOIN incident_neigh inb
ON sn.neighborhood = inb.neighborhood
ORDER BY sn.neighborhood;