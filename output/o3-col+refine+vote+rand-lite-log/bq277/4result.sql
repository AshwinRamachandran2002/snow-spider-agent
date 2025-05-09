-- Port in region '6585' that is both inside a U.S. state
-- and falls within the 34-kt wind-fields (or 100-nm fallback)
-- of the largest number of named (≥35 kt) North-Atlantic storms
SELECT
  index_number,
  port_name,
  COUNT(DISTINCT sid) AS storms_covering_port
FROM (
  -- All storm-point / port pairs where the port lies inside the storm area
  SELECT
    p.index_number,
    p.port_name,
    h.sid
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
    ON ST_WITHIN(p.port_geom, s.state_geom)                  -- keep only U.S. ports
  JOIN (
    -- North-Atlantic storm points with a radius (metres) around each point
    SELECT
      sid,
      name,
      ST_GEOGPOINT(longitude, latitude) AS storm_pt,
      -- radius in metres : 34-kt wind radius (nm) → metres, or 100-nm fallback
      COALESCE(
        NULLIF(
          GREATEST(
            IFNULL(usa_r34_ne, 0),
            IFNULL(usa_r34_se, 0),
            IFNULL(usa_r34_sw, 0),
            IFNULL(usa_r34_nw, 0)
          ), 0
        ),
        100
      ) * 1852 AS radius_m
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE basin = 'NA'
      AND name <> 'NOT_NAMED'
      AND usa_wind >= 35                                -- ≥35-kt (tropical-storm strength)
  ) AS h
    ON ST_DWITHIN(p.port_geom, h.storm_pt, h.radius_m)  -- port inside storm area
  WHERE p.region_number = '6585'                        -- requested region
) AS hits
GROUP BY index_number, port_name
ORDER BY storms_covering_port DESC
LIMIT 1;