-- State–level comparison of Project Sunroof technical‑potential metrics
-- at the Postal‑Code vs. Census‑Tract granularity
WITH
-- 1.  Per‑region calculations for both tables ------------------------------
postal_code AS (
  SELECT
    state_name,
    count_qualified,
    percent_covered,
    percent_qualified,
    number_of_panels_total,
    kw_total,
    yearly_sunlight_kwh_total,
    carbon_offset_metric_tons,
    existing_installs_count,
    -- adjusted potential buildings = qualified ÷ (covered% × suitable%)
    SAFE_DIVIDE(
      count_qualified * 10000,
      NULLIF(percent_covered * percent_qualified,0)
    ) AS adjusted_potential_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
),
census_tract AS (
  SELECT
    state_name,
    count_qualified,
    percent_covered,
    percent_qualified,
    number_of_panels_total,
    kw_total,
    yearly_sunlight_kwh_total,
    carbon_offset_metric_tons,
    existing_installs_count,
    SAFE_DIVIDE(
      count_qualified * 10000,
      NULLIF(percent_covered * percent_qualified,0)
    ) AS adjusted_potential_buildings
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
),

-- 2.  Aggregate to the state level for each geographic resolution ----------
state_postal AS (
  SELECT
    state_name,
    'postal_code'                    AS level,
    SUM(count_qualified)             AS total_qualified_buildings,
    AVG(percent_covered)             AS avg_percent_covered,
    AVG(percent_qualified)           AS avg_percent_qualified,
    SUM(number_of_panels_total)      AS total_panel_count,
    SUM(kw_total)                    AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)   AS energy_generation_potential_kwh,
    SUM(carbon_offset_metric_tons)   AS carbon_dioxide_offset_metric_tons,
    SUM(existing_installs_count)     AS current_installations,
    SUM(adjusted_potential_buildings) - SUM(existing_installs_count)
                                       AS potential_installation_gap
  FROM postal_code
  GROUP BY state_name
),
state_census AS (
  SELECT
    state_name,
    'census_tract'                   AS level,
    SUM(count_qualified)             AS total_qualified_buildings,
    AVG(percent_covered)             AS avg_percent_covered,
    AVG(percent_qualified)           AS avg_percent_qualified,
    SUM(number_of_panels_total)      AS total_panel_count,
    SUM(kw_total)                    AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)   AS energy_generation_potential_kwh,
    SUM(carbon_offset_metric_tons)   AS carbon_dioxide_offset_metric_tons,
    SUM(existing_installs_count)     AS current_installations,
    SUM(adjusted_potential_buildings) - SUM(existing_installs_count)
                                       AS potential_installation_gap
  FROM census_tract
  GROUP BY state_name
)

-- 3.  Combine both resolutions --------------------------------------------
SELECT *
FROM (
  SELECT * FROM state_postal
  UNION ALL
  SELECT * FROM state_census
)
ORDER BY state_name, level;