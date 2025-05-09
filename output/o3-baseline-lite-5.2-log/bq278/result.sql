-- State–level solar‑potential summary at both the ZIP‑code and Census‑tract granularities
WITH postal_level AS (
  SELECT
    state_name,
    'postal_code'           AS region_level,
    SUM(count_qualified)                         AS total_buildings_qualified,
    AVG(percent_covered)                         AS avg_percent_covered,
    AVG(percent_qualified)                       AS avg_percent_qualified,
    SUM(number_of_panels_total)                  AS total_panel_count,
    SUM(kw_total)                                AS total_kw_capacity_kw,
    SUM(yearly_sunlight_kwh_total)               AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)               AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                 AS current_installs,
    -- potential install gap = scale qualified bldgs to 100 % coverage then subtract installs
    SUM( CASE WHEN percent_covered > 0 
              THEN count_qualified * 100.0 / percent_covered 
              ELSE 0 END ) 
      - SUM(existing_installs_count)             AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
tract_level AS (
  SELECT
    state_name,
    'census_tract'          AS region_level,
    SUM(count_qualified)                         AS total_buildings_qualified,
    AVG(percent_covered)                         AS avg_percent_covered,
    AVG(percent_qualified)                       AS avg_percent_qualified,
    SUM(number_of_panels_total)                  AS total_panel_count,
    SUM(kw_total)                                AS total_kw_capacity_kw,
    SUM(yearly_sunlight_kwh_total)               AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)               AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                 AS current_installs,
    SUM( CASE WHEN percent_covered > 0 
              THEN count_qualified * 100.0 / percent_covered 
              ELSE 0 END ) 
      - SUM(existing_installs_count)             AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)
SELECT *
FROM postal_level
UNION ALL
SELECT *
FROM tract_level
ORDER BY state_name, region_level;