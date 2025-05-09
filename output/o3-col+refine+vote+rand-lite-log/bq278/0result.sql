-- Solar-potential “report card” — side-by-side comparison of
-- Postal-code- vs Census-tract-level results for every state

WITH zip AS (    -- aggregate the ZIP-code table
  SELECT
    state_name,
    SUM(count_qualified)                                                 AS total_buildings,
    ROUND(AVG(percent_covered)    ,4)                                    AS avg_percent_covered,
    ROUND(AVG(percent_qualified)  ,4)                                    AS avg_percent_suitable,
    SUM(number_of_panels_total)                                           AS total_panels,
    SUM(kw_total)                                                        AS total_kw,
    SUM(yearly_sunlight_kwh_total)                                       AS total_energy_kwh,
    SUM(carbon_offset_metric_tons)                                       AS total_carbon_offset_tons,
    SUM(existing_installs_count)                                         AS total_existing_installs,
    -- gap  =   Σ( Qualified / ( %Covered·%Suitable ) )  − Existing
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered * percent_qualified) / 10000.0     -- convert two %’s to a fraction
        )
      ) - SUM(existing_installs_count)
    ,4)                                                                  AS installation_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

ct AS (      -- aggregate the Census-tract table
  SELECT
    state_name,
    SUM(count_qualified)                                                 AS total_buildings,
    ROUND(AVG(percent_covered)    ,4)                                    AS avg_percent_covered,
    ROUND(AVG(percent_qualified)  ,4)                                    AS avg_percent_suitable,
    SUM(number_of_panels_total)                                           AS total_panels,
    SUM(kw_total)                                                        AS total_kw,
    SUM(yearly_sunlight_kwh_total)                                       AS total_energy_kwh,
    SUM(carbon_offset_metric_tons)                                       AS total_carbon_offset_tons,
    SUM(existing_installs_count)                                         AS total_existing_installs,
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered * percent_qualified) / 10000.0
        )
      ) - SUM(existing_installs_count)
    ,4)                                                                  AS installation_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(zip.state_name, ct.state_name)                    AS state_name,

  -- number of suitable buildings
  zip.total_buildings                                        AS zip_total_buildings,
  ct.total_buildings                                         AS ct_total_buildings,

  -- Google-Maps coverage (%)
  zip.avg_percent_covered                                    AS zip_avg_percent_covered,
  ct.avg_percent_covered                                     AS ct_avg_percent_covered,

  -- suitability within that coverage (%)
  zip.avg_percent_suitable                                   AS zip_avg_percent_suitable,
  ct.avg_percent_suitable                                    AS ct_avg_percent_suitable,

  -- panel count & capacity
  zip.total_panels                                           AS zip_total_panels,
  ct.total_panels                                            AS ct_total_panels,
  zip.total_kw                                               AS zip_total_kw,
  ct.total_kw                                                AS ct_total_kw,

  -- annual generation potential & CO₂ offset
  zip.total_energy_kwh                                       AS zip_total_energy_kwh,
  ct.total_energy_kwh                                        AS ct_total_energy_kwh,
  zip.total_carbon_offset_tons                               AS zip_total_carbon_offset_tons,
  ct.total_carbon_offset_tons                                AS ct_total_carbon_offset_tons,

  -- installations already present
  zip.total_existing_installs                                AS zip_existing_installs,
  ct.total_existing_installs                                 AS ct_existing_installs,

  -- “installation gap”
  zip.installation_gap                                       AS zip_installation_gap,
  ct.installation_gap                                        AS ct_installation_gap
FROM zip
FULL JOIN ct USING (state_name)
ORDER BY state_name;