/*  State-level solar-potential comparison between
    (a) postal-code aggregates and 
    (b) census-tract aggregates                                         */

WITH postal AS (
  SELECT
    state_name,
    SUM(count_qualified)                                    AS p_total_buildings_suitable,
    AVG(percent_covered)                                    AS p_avg_pct_covered,
    AVG(percent_qualified)                                  AS p_avg_pct_suitable_of_covered,
    SUM(number_of_panels_total)                             AS p_total_panel_count,
    SUM(kw_total)                                           AS p_total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                          AS p_total_kwh_generation,
    SUM(carbon_offset_metric_tons)                          AS p_total_co2_offset_tons,
    SUM(existing_installs_count)                            AS p_current_installed_buildings,
    -- potential-install gap = estimated total buildings − current installs
    SUM(
          count_qualified
          / NULLIF(percent_qualified,0) * 100              -- adjust for suitability %
          / NULLIF(percent_covered,0)                      -- adjust for Sunroof coverage %
        ) 
      - SUM(existing_installs_count)                        AS p_potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

census AS (
  SELECT
    state_name,
    SUM(count_qualified)                                    AS c_total_buildings_suitable,
    AVG(percent_covered)                                    AS c_avg_pct_covered,
    AVG(percent_qualified)                                  AS c_avg_pct_suitable_of_covered,
    SUM(number_of_panels_total)                             AS c_total_panel_count,
    SUM(kw_total)                                           AS c_total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                          AS c_total_kwh_generation,
    SUM(carbon_offset_metric_tons)                          AS c_total_co2_offset_tons,
    SUM(existing_installs_count)                            AS c_current_installed_buildings,
    SUM(
          count_qualified
          / NULLIF(percent_qualified,0) * 100              
          / NULLIF(percent_covered,0)                      
        ) 
      - SUM(existing_installs_count)                        AS c_potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(p.state_name, c.state_name)                                          AS state_name,

  /* -------- Postal-code metrics -------- */
  p_total_buildings_suitable,
  p_avg_pct_covered,
  p_avg_pct_suitable_of_covered,
  p_total_panel_count,
  p_total_kw_capacity,
  p_total_kwh_generation,
  p_total_co2_offset_tons,
  p_current_installed_buildings,
  p_potential_install_gap,

  /* -------- Census-tract metrics -------- */
  c_total_buildings_suitable,
  c_avg_pct_covered,
  c_avg_pct_suitable_of_covered,
  c_total_panel_count,
  c_total_kw_capacity,
  c_total_kwh_generation,
  c_total_co2_offset_tons,
  c_current_installed_buildings,
  c_potential_install_gap

FROM postal p
FULL OUTER JOIN census c
ON p.state_name = c.state_name
ORDER BY state_name;