WITH postal_code AS (
  SELECT
    'postal_code'                                                AS level,
    state_name                                                   AS state,
    SUM(count_qualified)                                         AS total_buildings_available,
    ROUND(AVG(percent_covered),4)                                AS avg_pct_area_covered,
    ROUND(AVG(percent_qualified),4)                              AS avg_pct_area_suitable,
    SUM(number_of_panels_total)                                  AS total_potential_panel_count,
    ROUND(SUM(kw_total),4)                                       AS total_kw_capacity,
    ROUND(SUM(yearly_sunlight_kwh_total),4)                      AS yearly_energy_generation_potential_kwh,
    ROUND(SUM(carbon_offset_metric_tons),4)                      AS carbon_dioxide_offset_tons,
    SUM(existing_installs_count)                                 AS current_buildings_with_solar,
    ROUND(
      ( SUM(count_qualified)
        / (AVG(percent_qualified) / 100.0)
        / (AVG(percent_covered)   / 100.0)
      ) - SUM(existing_installs_count)
    ,4)                                                          AS potential_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
census_tract AS (
  SELECT
    'census_tract'                                               AS level,
    state_name                                                   AS state,
    SUM(count_qualified)                                         AS total_buildings_available,
    ROUND(AVG(percent_covered),4)                                AS avg_pct_area_covered,
    ROUND(AVG(percent_qualified),4)                              AS avg_pct_area_suitable,
    SUM(number_of_panels_total)                                  AS total_potential_panel_count,
    ROUND(SUM(kw_total),4)                                       AS total_kw_capacity,
    ROUND(SUM(yearly_sunlight_kwh_total),4)                      AS yearly_energy_generation_potential_kwh,
    ROUND(SUM(carbon_offset_metric_tons),4)                      AS carbon_dioxide_offset_tons,
    SUM(existing_installs_count)                                 AS current_buildings_with_solar,
    ROUND(
      ( SUM(count_qualified)
        / (AVG(percent_qualified) / 100.0)
        / (AVG(percent_covered)   / 100.0)
      ) - SUM(existing_installs_count)
    ,4)                                                          AS potential_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT *
FROM postal_code
UNION ALL
SELECT *
FROM census_tract
ORDER BY state, level;