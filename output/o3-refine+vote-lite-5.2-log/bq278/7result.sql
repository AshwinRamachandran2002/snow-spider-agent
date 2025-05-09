/*  Comparison of solar potential by U.S. state at two geographic levels:
    1) ZIP / postal code     -> solar_potential_by_postal_code
    2) Census tract          -> solar_potential_by_censustract

    For every state and level the query returns:
      • total_qualified_buildings      – Σ(count_qualified)
      • avg_percent_covered            – AVG(percent_covered)
      • avg_percent_qualified          – AVG(percent_qualified)
      • total_panel_count              – Σ(number_of_panels_total)
      • total_kw_capacity_kw           – Σ(kw_total)
      • total_energy_generation_kwh    – Σ(yearly_sunlight_kwh_total)
      • total_carbon_offset_metric_tons– Σ(carbon_offset_metric_tons)
      • current_installs               – Σ(existing_installs_count)
      • potential_install_gap          – Σ( count_qualified /
                                             (percent_covered/100) /
                                             (percent_qualified/100) )
                                         − current_installs
*/
WITH postal AS (
  SELECT
    'postal_code'                           AS geographic_level,
    state_name,
    SUM(count_qualified)                    AS total_qualified_buildings,
    AVG(percent_covered)                    AS avg_percent_covered,
    AVG(percent_qualified)                  AS avg_percent_qualified,
    SUM(number_of_panels_total)             AS total_panel_count,
    SUM(kw_total)                           AS total_kw_capacity_kw,
    SUM(yearly_sunlight_kwh_total)          AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)          AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)            AS current_installs,
    -- Estimate total viable buildings by back‑calculating for coverage & suitability
    SUM(
      CASE
        WHEN percent_covered   > 0
         AND percent_qualified > 0
        THEN count_qualified / (percent_covered/100) / (percent_qualified/100)
      END
    ) - SUM(existing_installs_count)        AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
census AS (
  SELECT
    'census_tract'                          AS geographic_level,
    state_name,
    SUM(count_qualified)                    AS total_qualified_buildings,
    AVG(percent_covered)                    AS avg_percent_covered,
    AVG(percent_qualified)                  AS avg_percent_qualified,
    SUM(number_of_panels_total)             AS total_panel_count,
    SUM(kw_total)                           AS total_kw_capacity_kw,
    SUM(yearly_sunlight_kwh_total)          AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)          AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)            AS current_installs,
    SUM(
      CASE
        WHEN percent_covered   > 0
         AND percent_qualified > 0
        THEN count_qualified / (percent_covered/100) / (percent_qualified/100)
      END
    ) - SUM(existing_installs_count)        AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT *
FROM postal
UNION ALL
SELECT *
FROM census
ORDER BY state_name, geographic_level;