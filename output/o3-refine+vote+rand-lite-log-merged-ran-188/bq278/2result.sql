/*  State-level solar-potential comparison between
    POSTAL-CODE and CENSUS-TRACT granularity                             */

WITH postal AS (
  SELECT
    state_name,
    /* totals & averages at POSTAL-CODE level */
    SUM(count_qualified)                                               AS postal_total_qualified_bldgs,
    ROUND(AVG(percent_covered),4)                                      AS postal_avg_pct_covered,
    ROUND(AVG(percent_qualified),4)                                    AS postal_avg_pct_suitable,
    SUM(number_of_panels_total)                                        AS postal_total_panel_count,
    SUM(kw_total)                                                      AS postal_total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                     AS postal_total_kwh_generation,
    SUM(carbon_offset_metric_tons)                                     AS postal_total_co2_offset,
    SUM(existing_installs_count)                                       AS postal_current_installs,
    /* GAP = estimated # buildings − current installs */
    SUM(
        SAFE_DIVIDE(count_qualified,
                    (percent_covered/100.0) * (percent_qualified/100.0))
       ) - SUM(existing_installs_count)                                AS postal_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
tract AS (
  SELECT
    state_name,
    /* totals & averages at CENSUS-TRACT level */
    SUM(count_qualified)                                               AS tract_total_qualified_bldgs,
    ROUND(AVG(percent_covered),4)                                      AS tract_avg_pct_covered,
    ROUND(AVG(percent_qualified),4)                                    AS tract_avg_pct_suitable,
    SUM(number_of_panels_total)                                        AS tract_total_panel_count,
    SUM(kw_total)                                                      AS tract_total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                     AS tract_total_kwh_generation,
    SUM(carbon_offset_metric_tons)                                     AS tract_total_co2_offset,
    SUM(existing_installs_count)                                       AS tract_current_installs,
    /* GAP = estimated # buildings − current installs */
    SUM(
        SAFE_DIVIDE(count_qualified,
                    (percent_covered/100.0) * (percent_qualified/100.0))
       ) - SUM(existing_installs_count)                                AS tract_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(p.state_name, t.state_name)                                  AS state_name,

  /* -------- POSTAL-CODE METRICS -------- */
  p.postal_total_qualified_bldgs,
  p.postal_avg_pct_covered,
  p.postal_avg_pct_suitable,
  p.postal_total_panel_count,
  p.postal_total_kw_capacity,
  p.postal_total_kwh_generation,
  p.postal_total_co2_offset,
  p.postal_current_installs,
  p.postal_install_gap,

  /* -------- CENSUS-TRACT METRICS -------- */
  t.tract_total_qualified_bldgs,
  t.tract_avg_pct_covered,
  t.tract_avg_pct_suitable,
  t.tract_total_panel_count,
  t.tract_total_kw_capacity,
  t.tract_total_kwh_generation,
  t.tract_total_co2_offset,
  t.tract_current_installs,
  t.tract_install_gap

FROM postal p
FULL JOIN tract t USING (state_name)
ORDER BY state_name;