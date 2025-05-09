/*  Solar‑potential comparison between POSTAL‑CODE and CENSUS‑TRACT levels
    ─────────────────────────────────────────────────────────────────────
    For every state we aggregate, per spatial level:
      • total_qualified_buildings      – Σ(count_qualified)
      • avg_percent_covered            – AVG(percent_covered)
      • avg_percent_qualified          – AVG(percent_qualified)
      • total_panels                   – Σ(number_of_panels_total)
      • total_kw_capacity              – Σ(kw_total)
      • total_energy_generation_kwh    – Σ(yearly_sunlight_kwh_total)
      • total_carbon_offset_metric_tons– Σ(carbon_offset_metric_tons)
      • existing_installs              – Σ(existing_installs_count)
      • potential_installation_gap     –  Σ( (count_qualified / (percent_covered/100))  
                                              - existing_installs_count )
        (i.e., scale the known qualified buildings by the coverage
         percentage to approximate total state‑wide suitable buildings,
         then subtract the installs already in place)                                                    */

WITH postal AS (
  SELECT
      state_name,
      'postal_code'                                                 AS level,
      SUM(count_qualified)                                          AS total_qualified_buildings,
      AVG(percent_covered)                                          AS avg_percent_covered,
      AVG(percent_qualified)                                        AS avg_percent_qualified,
      SUM(number_of_panels_total)                                   AS total_panels,
      SUM(kw_total)                                                 AS total_kw_capacity,
      SUM(yearly_sunlight_kwh_total)                                AS total_energy_generation_kwh,
      SUM(carbon_offset_metric_tons)                                AS total_carbon_offset_metric_tons,
      SUM(existing_installs_count)                                  AS existing_installs,
      SUM(
          SAFE_DIVIDE(count_qualified , percent_covered/100)
          - existing_installs_count
      )                                                             AS potential_installation_gap
  FROM  `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

tract AS (
  SELECT
      state_name,
      'census_tract'                                                AS level,
      SUM(count_qualified)                                          AS total_qualified_buildings,
      AVG(percent_covered)                                          AS avg_percent_covered,
      AVG(percent_qualified)                                        AS avg_percent_qualified,
      SUM(number_of_panels_total)                                   AS total_panels,
      SUM(kw_total)                                                 AS total_kw_capacity,
      SUM(yearly_sunlight_kwh_total)                                AS total_energy_generation_kwh,
      SUM(carbon_offset_metric_tons)                                AS total_carbon_offset_metric_tons,
      SUM(existing_installs_count)                                  AS existing_installs,
      SUM(
          SAFE_DIVIDE(count_qualified , percent_covered/100)
          - existing_installs_count
      )                                                             AS potential_installation_gap
  FROM  `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT *
FROM   postal
UNION ALL
SELECT *
FROM   tract
ORDER  BY state_name, level;