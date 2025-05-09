/*  State–level solar-potential comparison  
    – Postal-code view vs. Census-tract view                                  */

WITH postal AS (
  SELECT
    `state_name`,
    /* core totals */
    SUM(`count_qualified`)                        AS postal_total_buildings,
    AVG(`percent_covered`)                        AS postal_avg_percent_covered,
    AVG(`percent_qualified`)                      AS postal_avg_percent_qualified,
    SUM(`number_of_panels_total`)                 AS postal_total_panel_count,
    SUM(`kw_total`)                               AS postal_total_kw_capacity,
    SUM(`yearly_sunlight_kwh_total`)              AS postal_total_energy_kwh,
    SUM(`carbon_offset_metric_tons`)              AS postal_total_co2_offset_tons,
    SUM(`existing_installs_count`)                AS postal_current_installs,

    /* gap = potential_buildings – current_installs
       potential_buildings = count_qualified /
                             (percent_qualified/100) /
                             (percent_covered/100)                               */
    SUM(
      SAFE_DIVIDE(
        SAFE_DIVIDE(`count_qualified`, NULLIF(`percent_qualified`,0)/100.0),
        NULLIF(`percent_covered`,0)/100.0
      )
    ) - SUM(`existing_installs_count`)            AS postal_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY `state_name`
),

census AS (
  SELECT
    `state_name`,
    SUM(`count_qualified`)                        AS census_total_buildings,
    AVG(`percent_covered`)                        AS census_avg_percent_covered,
    AVG(`percent_qualified`)                      AS census_avg_percent_qualified,
    SUM(`number_of_panels_total`)                 AS census_total_panel_count,
    SUM(`kw_total`)                               AS census_total_kw_capacity,
    SUM(`yearly_sunlight_kwh_total`)              AS census_total_energy_kwh,
    SUM(`carbon_offset_metric_tons`)              AS census_total_co2_offset_tons,
    SUM(`existing_installs_count`)                AS census_current_installs,
    SUM(
      SAFE_DIVIDE(
        SAFE_DIVIDE(`count_qualified`, NULLIF(`percent_qualified`,0)/100.0),
        NULLIF(`percent_covered`,0)/100.0
      )
    ) - SUM(`existing_installs_count`)            AS census_gap_installations
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY `state_name`
)

SELECT
  COALESCE(p.`state_name`, c.`state_name`)        AS state_name,

  /* ---------------- postal-code level ---------------- */
  p.postal_total_buildings,
  p.postal_avg_percent_covered,
  p.postal_avg_percent_qualified,
  p.postal_total_panel_count,
  p.postal_total_kw_capacity,
  p.postal_total_energy_kwh,
  p.postal_total_co2_offset_tons,
  p.postal_current_installs,
  p.postal_gap_installations,

  /* ---------------- census-tract level --------------- */
  c.census_total_buildings,
  c.census_avg_percent_covered,
  c.census_avg_percent_qualified,
  c.census_total_panel_count,
  c.census_total_kw_capacity,
  c.census_total_energy_kwh,
  c.census_total_co2_offset_tons,
  c.census_current_installs,
  c.census_gap_installations

FROM postal AS p
FULL JOIN census AS c
ON p.`state_name` = c.`state_name`
ORDER BY state_name;