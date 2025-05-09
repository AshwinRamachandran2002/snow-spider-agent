-- Solar‑potential comparison between postal–code and census‑tract aggregation levels
WITH state_level_stats AS (
  -- --------------------------
  -- 1.  ZIP / Postal‑code view
  -- --------------------------
  SELECT
      state_name,
      'postal_code'                          AS region_level,
      SUM(count_qualified)                   AS total_qualified_buildings,
      AVG(percent_covered)                   AS avg_percent_covered,
      AVG(percent_qualified)                 AS avg_percent_qualified,
      SUM(number_of_panels_total)            AS total_panel_count,
      SUM(kw_total)                          AS total_kw_capacity,
      SUM(yearly_sunlight_kwh_total)         AS total_energy_kwh,
      SUM(carbon_offset_metric_tons)         AS total_co2_offset_tons,
      SUM(existing_installs_count)           AS current_installs,
      -- potential‑install gap = scale up qualified count by coverage & suitability, then subtract installs
      SUM(
        SAFE_DIVIDE(
          SAFE_DIVIDE(count_qualified , NULLIF(percent_qualified ,0)/100.0) ,
          NULLIF(percent_covered ,0)/100.0
        )
      )                                       -
      SUM(existing_installs_count)           AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name

  UNION ALL

  -- ------------------------------
  -- 2.  Census‑tract level view
  -- ------------------------------
  SELECT
      state_name,
      'census_tract'                         AS region_level,
      SUM(count_qualified)                   AS total_qualified_buildings,
      AVG(percent_covered)                   AS avg_percent_covered,
      AVG(percent_qualified)                 AS avg_percent_qualified,
      SUM(number_of_panels_total)            AS total_panel_count,
      SUM(kw_total)                          AS total_kw_capacity,
      SUM(yearly_sunlight_kwh_total)         AS total_energy_kwh,
      SUM(carbon_offset_metric_tons)         AS total_co2_offset_tons,
      SUM(existing_installs_count)           AS current_installs,
      SUM(
        SAFE_DIVIDE(
          SAFE_DIVIDE(count_qualified , NULLIF(percent_qualified ,0)/100.0) ,
          NULLIF(percent_covered ,0)/100.0
        )
      )                                       -
      SUM(existing_installs_count)           AS potential_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT *
FROM   state_level_stats
ORDER  BY state_name, region_level;