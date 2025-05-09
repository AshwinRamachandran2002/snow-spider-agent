-- State–level comparison of solar‑potential metrics at the
-- postal‑code and census‑tract granularities
WITH postal AS (
  SELECT
    state_name,
    'postal_code'                                         AS granularity,
    SUM(count_qualified)                                  AS total_buildings_qualified,
    AVG(percent_covered)                                  AS avg_percent_covered,
    AVG(percent_qualified)                                AS avg_percent_qualified,
    SUM(number_of_panels_total)                           AS total_panel_count,
    SUM(kw_total)                                         AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                        AS total_energy_kwh,
    SUM(carbon_offset_metric_tons)                        AS total_carbon_offset,
    SUM(existing_installs_count)                          AS existing_installs,
    -- scale qualified buildings by coverage and suitability percentages
    SUM(
      count_qualified
      / (NULLIF(percent_covered ,0)/100.0)
      / (NULLIF(percent_qualified,0)/100.0)
    )                                                     AS adjusted_potential_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
tract AS (
  SELECT
    state_name,
    'census_tract'                                        AS granularity,
    SUM(count_qualified)                                  AS total_buildings_qualified,
    AVG(percent_covered)                                  AS avg_percent_covered,
    AVG(percent_qualified)                                AS avg_percent_qualified,
    SUM(number_of_panels_total)                           AS total_panel_count,
    SUM(kw_total)                                         AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                        AS total_energy_kwh,
    SUM(carbon_offset_metric_tons)                        AS total_carbon_offset,
    SUM(existing_installs_count)                          AS existing_installs,
    SUM(
      count_qualified
      / (NULLIF(percent_covered ,0)/100.0)
      / (NULLIF(percent_qualified,0)/100.0)
    )                                                     AS adjusted_potential_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)
SELECT
  state_name,
  granularity,
  total_buildings_qualified,
  avg_percent_covered,
  avg_percent_qualified,
  total_panel_count,
  total_kw_capacity,
  total_energy_kwh,
  total_carbon_offset,
  existing_installs,
  -- gap = adjusted potential – current installs
  (adjusted_potential_buildings - existing_installs)      AS potential_installations_gap
FROM (
  SELECT * FROM postal
  UNION ALL
  SELECT * FROM tract
)
ORDER BY state_name, granularity;