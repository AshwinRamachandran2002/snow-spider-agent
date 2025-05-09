-- Solar‑potential comparison by State, shown separately for
-- Postal‑Code–level data and Census‑Tract–level data.

WITH postal AS (
  SELECT
    state_name,
    'postal_code'                           AS region_level,
    SUM(count_qualified)                    AS total_qualified_buildings,
    AVG(percent_covered)                    AS avg_percent_covered,
    AVG(percent_qualified)                  AS avg_percent_qualified,
    SUM(number_of_panels_total)             AS total_panel_count,
    SUM(kw_total)                           AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)          AS total_yearly_generation_kwh,
    SUM(carbon_offset_metric_tons)          AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)            AS total_existing_installations,

    -- Adjust qualified‑building count for Google‑Maps coverage
    -- (estimate of suitable buildings if 100 % of structures were mapped)
    SUM(count_qualified * 100 / NULLIF(percent_covered,0)) AS adjusted_suitable_buildings,

    -- Potential installation gap = adjusted suitable – current installs
    SUM(count_qualified * 100 / NULLIF(percent_covered,0))
      - SUM(existing_installs_count)        AS potential_installation_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

tract AS (
  SELECT
    state_name,
    'census_tract'                          AS region_level,
    SUM(count_qualified)                    AS total_qualified_buildings,
    AVG(percent_covered)                    AS avg_percent_covered,
    AVG(percent_qualified)                  AS avg_percent_qualified,
    SUM(number_of_panels_total)             AS total_panel_count,
    SUM(kw_total)                           AS total_kw_capacity,
    SUM(yearly_sunlight_kwh_total)          AS total_yearly_generation_kwh,
    SUM(carbon_offset_metric_tons)          AS total_carbon_offset_metric_tons,
    SUM(existing_installs_count)            AS total_existing_installations,

    SUM(count_qualified * 100 / NULLIF(percent_covered,0)) AS adjusted_suitable_buildings,
    SUM(count_qualified * 100 / NULLIF(percent_covered,0))
      - SUM(existing_installs_count)        AS potential_installation_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

-- Combine both granularities for side‑by‑side comparison
SELECT *
FROM (
  SELECT * FROM postal
  UNION ALL
  SELECT * FROM tract
)
ORDER BY state_name, region_level;