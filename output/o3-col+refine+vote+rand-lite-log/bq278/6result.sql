/*  State-by-state solar-potential comparison
    – Postal-code (pc) vs Census-tract (ct) granularity                         */

WITH pc AS (    -- postal-code level aggregates
  SELECT
    state_name,
    SUM(count_qualified)                                                   AS total_buildings_qualified,
    AVG(percent_covered)                                                   AS avg_covered_pct,
    AVG(percent_qualified)                                                 AS avg_suitable_pct,
    SUM(number_of_panels_total)                                            AS total_panel_count,
    SUM(kw_total)                                                          AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                         AS total_kwh_potential,
    SUM(carbon_offset_metric_tons)                                         AS total_co2_offset_tons,
    SUM(existing_installs_count)                                           AS current_installs,
    -- adjust for imagery coverage & suitability
    SUM(
      SAFE_DIVIDE(
        count_qualified,
        (NULLIF(percent_covered,0)/100) * (NULLIF(percent_qualified,0)/100)
      )
    )                                                                      AS adjusted_total_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
ct AS (    -- census-tract level aggregates
  SELECT
    state_name,
    SUM(count_qualified)                                                   AS total_buildings_qualified,
    AVG(percent_covered)                                                   AS avg_covered_pct,
    AVG(percent_qualified)                                                 AS avg_suitable_pct,
    SUM(number_of_panels_total)                                            AS total_panel_count,
    SUM(kw_total)                                                          AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                         AS total_kwh_potential,
    SUM(carbon_offset_metric_tons)                                         AS total_co2_offset_tons,
    SUM(existing_installs_count)                                           AS current_installs,
    SUM(
      SAFE_DIVIDE(
        count_qualified,
        (NULLIF(percent_covered,0)/100) * (NULLIF(percent_qualified,0)/100)
      )
    )                                                                      AS adjusted_total_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(pc.state_name, ct.state_name)                                AS state_name,

  /* ---------- postal-code metrics ---------- */
  pc.total_buildings_qualified                                          AS pc_buildings_qualified,
  pc.avg_covered_pct                                                    AS pc_avg_covered_pct,
  pc.avg_suitable_pct                                                   AS pc_avg_suitable_pct,
  pc.total_panel_count                                                  AS pc_total_panel_count,
  pc.total_kw_capacity                                                  AS pc_total_kw_capacity,
  pc.total_kwh_potential                                                AS pc_total_kwh_potential,
  pc.total_co2_offset_tons                                              AS pc_total_co2_offset_tons,
  pc.current_installs                                                   AS pc_current_installs,
  pc.adjusted_total_buildings - pc.current_installs                     AS pc_gap_installations,

  /* ---------- census-tract metrics ---------- */
  ct.total_buildings_qualified                                          AS ct_buildings_qualified,
  ct.avg_covered_pct                                                    AS ct_avg_covered_pct,
  ct.avg_suitable_pct                                                   AS ct_avg_suitable_pct,
  ct.total_panel_count                                                  AS ct_total_panel_count,
  ct.total_kw_capacity                                                  AS ct_total_kw_capacity,
  ct.total_kwh_potential                                                AS ct_total_kwh_potential,
  ct.total_co2_offset_tons                                              AS ct_total_co2_offset_tons,
  ct.current_installs                                                   AS ct_current_installs,
  ct.adjusted_total_buildings - ct.current_installs                     AS ct_gap_installations

FROM pc
FULL JOIN ct USING (state_name)
ORDER BY state_name;