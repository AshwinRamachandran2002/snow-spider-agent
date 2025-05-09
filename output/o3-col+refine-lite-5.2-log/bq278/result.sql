-- State–level solar‑potential comparison at both geographic resolutions
WITH postal_code_level AS (
  SELECT
    'postal_code_level'                                            AS level_type,
    state_name,
    SUM(count_qualified)                                           AS tot_buildings_qualified,
    AVG(percent_covered)                                           AS avg_pct_covered,
    AVG(percent_qualified)                                         AS avg_pct_qualified,
    SUM(number_of_panels_total)                                    AS tot_panel_cnt,
    SUM(kw_total)                                                  AS tot_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                 AS tot_kwh_potential,
    SUM(carbon_offset_metric_tons)                                 AS tot_co2_offset_tons,
    SUM(existing_installs_count)                                   AS current_installs,

    -- gap = theoretical buildings (adjusted for coverage & suitability)
    --       minus the number already installed
    SUM(
          count_qualified /
          (NULLIF(percent_qualified,0) / 100) /
          (NULLIF(percent_covered ,0) / 100)
        ) - SUM(existing_installs_count)                           AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

census_tract_level AS (
  SELECT
    'census_tract_level'                                           AS level_type,
    state_name,
    SUM(count_qualified)                                           AS tot_buildings_qualified,
    AVG(percent_covered)                                           AS avg_pct_covered,
    AVG(percent_qualified)                                         AS avg_pct_qualified,
    SUM(number_of_panels_total)                                    AS tot_panel_cnt,
    SUM(kw_total)                                                  AS tot_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                 AS tot_kwh_potential,
    SUM(carbon_offset_metric_tons)                                 AS tot_co2_offset_tons,
    SUM(existing_installs_count)                                   AS current_installs,
    SUM(
          count_qualified /
          (NULLIF(percent_qualified,0) / 100) /
          (NULLIF(percent_covered ,0) / 100)
        ) - SUM(existing_installs_count)                           AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT *
FROM postal_code_level
UNION ALL
SELECT *
FROM census_tract_level
ORDER BY state_name, level_type;