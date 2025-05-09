/* Solar‑potential comparison by state – postal code vs census tract */
WITH postal AS (
  SELECT
    'postal_code'                                           AS level,
    state_name                                              AS state,
    SUM(count_qualified)                                    AS total_buildings_available,
    ROUND(AVG(percent_covered), 4)                          AS avg_pct_area_covered,
    ROUND(AVG(percent_qualified), 4)                        AS avg_pct_area_suitable,
    SUM(number_of_panels_total)                             AS total_potential_panel_count,
    ROUND(SUM(kw_total), 4)                                 AS total_kw_capacity,
    ROUND(SUM(yearly_sunlight_kwh_total), 4)                AS yearly_energy_generation_potential_kwh,
    ROUND(SUM(carbon_offset_metric_tons), 4)                AS carbon_dioxide_offset_tons,
    SUM(existing_installs_count)                            AS current_buildings_with_solar,
    ROUND(
      SUM(count_qualified / (percent_covered / 100.0))
      - SUM(existing_installs_count), 4)                    AS potential_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  WHERE percent_covered > 0
  GROUP BY state_name
),
tract AS (
  SELECT
    'census_tract'                                          AS level,
    state_name                                              AS state,
    SUM(count_qualified)                                    AS total_buildings_available,
    ROUND(AVG(percent_covered), 4)                          AS avg_pct_area_covered,
    ROUND(AVG(percent_qualified), 4)                        AS avg_pct_area_suitable,
    SUM(number_of_panels_total)                             AS total_potential_panel_count,
    ROUND(SUM(kw_total), 4)                                 AS total_kw_capacity,
    ROUND(SUM(yearly_sunlight_kwh_total), 4)                AS yearly_energy_generation_potential_kwh,
    ROUND(SUM(carbon_offset_metric_tons), 4)                AS carbon_dioxide_offset_tons,
    SUM(existing_installs_count)                            AS current_buildings_with_solar,
    ROUND(
      SUM(count_qualified / (percent_covered / 100.0))
      - SUM(existing_installs_count), 4)                    AS potential_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  WHERE percent_covered > 0
  GROUP BY state_name
)

SELECT
  level,
  state,
  total_buildings_available,
  avg_pct_area_covered,
  avg_pct_area_suitable,
  total_potential_panel_count,
  total_kw_capacity,
  yearly_energy_generation_potential_kwh,
  carbon_dioxide_offset_tons,
  current_buildings_with_solar,
  potential_gap_installations
FROM (
  SELECT * FROM postal
  UNION ALL
  SELECT * FROM tract
)
ORDER BY state, level;