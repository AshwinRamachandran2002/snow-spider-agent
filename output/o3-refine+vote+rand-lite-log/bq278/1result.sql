/*  State–level solar–potential comparison at two geographic granularities          */
/*  – postal‐code and census‐tract – with all figures requested in the prompt.       */

WITH postal AS (      -- 1.  Aggregate ZIP‑code level information per state
  SELECT
    state_name,
    SUM(count_qualified)                                                       AS total_qualified_buildings,
    ROUND(AVG(percent_covered),     4)                                         AS avg_percent_covered,
    ROUND(AVG(percent_qualified),   4)                                         AS avg_percent_qualified,
    SUM(number_of_panels_total)                                                AS total_panel_count,
    SUM(kw_total)                                                              AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                             AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)                                             AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                                               AS current_installs,
    --  Estimate total buildings Google Maps could host, then compute the gap.
    SUM(
        IF(percent_covered  > 0 AND percent_qualified > 0,
           count_qualified / (percent_qualified/100) / (percent_covered/100),
           0)
    )                                                                          AS adjusted_total_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),
tract AS (       -- 2.  Aggregate census‑tract level information per state
  SELECT
    state_name,
    SUM(count_qualified)                                                       AS total_qualified_buildings,
    ROUND(AVG(percent_covered),     4)                                         AS avg_percent_covered,
    ROUND(AVG(percent_qualified),   4)                                         AS avg_percent_qualified,
    SUM(number_of_panels_total)                                                AS total_panel_count,
    SUM(kw_total)                                                              AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)                                             AS total_energy_generation_kwh,
    SUM(carbon_offset_metric_tons)                                             AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)                                               AS current_installs,
    SUM(
        IF(percent_covered  > 0 AND percent_qualified > 0,
           count_qualified / (percent_qualified/100) / (percent_covered/100),
           0)
    )                                                                          AS adjusted_total_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
),
postal_final AS ( -- 3.  Prepare postal‑code results with gap calculation
  SELECT
    state_name,
    'postal_code'                                               AS geographic_level,
    total_qualified_buildings,
    avg_percent_covered,
    avg_percent_qualified,
    total_panel_count,
    total_kw_capacity,
    total_energy_generation_kwh,
    total_carbon_offset_metric_tons,
    current_installs,
    CAST(ROUND(adjusted_total_buildings - current_installs) AS INT64) AS potential_installation_gap
  FROM postal
),
tract_final AS (  -- 4.  Prepare census‑tract results with gap calculation
  SELECT
    state_name,
    'census_tract'                                              AS geographic_level,
    total_qualified_buildings,
    avg_percent_covered,
    avg_percent_qualified,
    total_panel_count,
    total_kw_capacity,
    total_energy_generation_kwh,
    total_carbon_offset_metric_tons,
    current_installs,
    CAST(ROUND(adjusted_total_buildings - current_installs) AS INT64) AS potential_installation_gap
  FROM tract
)

-- 5.  Combine and show the comparison
SELECT *
FROM  (
  SELECT * FROM postal_final
  UNION ALL
  SELECT * FROM tract_final
)
ORDER BY state_name, geographic_level;