WITH postal_state AS (
  SELECT
    state_name,
    SUM(count_qualified)                                                      AS total_buildings_available,
    AVG(percent_covered)                                                      AS avg_percent_covered,
    AVG(percent_qualified)                                                    AS avg_percent_qualified,
    SUM(number_of_panels_total)                                               AS total_panel_count,
    SUM(kw_total)                                                             AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                            AS total_energy_potential_kwh,
    SUM(carbon_offset_metric_tons)                                            AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                                              AS current_installs,
    -- potential installations adjusted for coverage and suitability minus current installs
    SUM(
      SAFE_DIVIDE(count_qualified * 10000,
                  NULLIF(percent_covered * percent_qualified,0))
    ) - SUM(existing_installs_count)                                          AS gap_potential_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
census_state AS (
  SELECT
    state_name,
    SUM(count_qualified)                                                      AS total_buildings_available,
    AVG(percent_covered)                                                      AS avg_percent_covered,
    AVG(percent_qualified)                                                    AS avg_percent_qualified,
    SUM(number_of_panels_total)                                               AS total_panel_count,
    SUM(kw_total)                                                             AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                            AS total_energy_potential_kwh,
    SUM(carbon_offset_metric_tons)                                            AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                                              AS current_installs,
    -- potential installations adjusted for coverage and suitability minus current installs
    SUM(
      SAFE_DIVIDE(count_qualified * 10000,
                  NULLIF(percent_covered * percent_qualified,0))
    ) - SUM(existing_installs_count)                                          AS gap_potential_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  state_name,
  'postal_code'      AS data_level,
  total_buildings_available,
  avg_percent_covered,
  avg_percent_qualified,
  total_panel_count,
  total_kw_capacity,
  total_energy_potential_kwh,
  total_carbon_offset_metric_tons,
  current_installs,
  gap_potential_installations
FROM postal_state

UNION ALL

SELECT
  state_name,
  'census_tract'     AS data_level,
  total_buildings_available,
  avg_percent_covered,
  avg_percent_qualified,
  total_panel_count,
  total_kw_capacity,
  total_energy_potential_kwh,
  total_carbon_offset_metric_tons,
  current_installs,
  gap_potential_installations
FROM census_state

ORDER BY state_name, data_level;