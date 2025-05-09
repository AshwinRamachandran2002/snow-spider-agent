/*  Comparison of solar-potential metrics at the ZIP-code vs. Census-tract level
    for every U.S. state (and territory) that appears in the Sunroof data.       */

WITH zip AS (
  SELECT
    state_name,
    SUM(count_qualified)                                                    AS zip_buildings_qualified,
    ROUND(AVG(percent_covered)   ,4)                                        AS zip_avg_percent_covered,
    ROUND(AVG(percent_qualified) ,4)                                        AS zip_avg_percent_qualified,
    SUM(number_of_panels_total)                                             AS zip_panel_count_total,
    SUM(kw_total)                                                           AS zip_kw_capacity_total,
    SUM(yearly_sunlight_kwh_total)                                          AS zip_kwh_generation_total,
    SUM(carbon_offset_metric_tons)                                          AS zip_carbon_offset_total,
    SUM(existing_installs_count)                                            AS zip_current_installs,
    -- gap  =  (qualified / coverage%) – already-installed
    SUM( SAFE_DIVIDE(count_qualified , percent_covered/100.0) ) 
      - SUM(existing_installs_count)                                        AS zip_potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
tract AS (
  SELECT
    state_name,
    SUM(count_qualified)                                                    AS tract_buildings_qualified,
    ROUND(AVG(percent_covered)   ,4)                                        AS tract_avg_percent_covered,
    ROUND(AVG(percent_qualified) ,4)                                        AS tract_avg_percent_qualified,
    SUM(number_of_panels_total)                                             AS tract_panel_count_total,
    SUM(kw_total)                                                           AS tract_kw_capacity_total,
    SUM(yearly_sunlight_kwh_total)                                          AS tract_kwh_generation_total,
    SUM(carbon_offset_metric_tons)                                          AS tract_carbon_offset_total,
    SUM(existing_installs_count)                                            AS tract_current_installs,
    SUM( SAFE_DIVIDE(count_qualified , percent_covered/100.0) ) 
      - SUM(existing_installs_count)                                        AS tract_potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(z.state_name, t.state_name)                                      AS state_name,

  /* -------- ZIP-level metrics -------- */
  z.zip_buildings_qualified,
  z.zip_avg_percent_covered,
  z.zip_avg_percent_qualified,
  z.zip_panel_count_total,
  z.zip_kw_capacity_total,
  z.zip_kwh_generation_total,
  z.zip_carbon_offset_total,
  z.zip_current_installs,
  z.zip_potential_install_gap,

  /* ------ Census-tract-level metrics ------ */
  t.tract_buildings_qualified,
  t.tract_avg_percent_covered,
  t.tract_avg_percent_qualified,
  t.tract_panel_count_total,
  t.tract_kw_capacity_total,
  t.tract_kwh_generation_total,
  t.tract_carbon_offset_total,
  t.tract_current_installs,
  t.tract_potential_install_gap

FROM zip   z
FULL OUTER JOIN tract t USING (state_name)
ORDER BY state_name;