/*  Detailed state-level comparison of solar potential
    between ZIP-code and census-tract resolutions           */
WITH
/* ---------- ZIP-code aggregation ---------- */
zip AS (
  SELECT
    state_name,
    /* core metrics */
    SUM(count_qualified)                                                   AS zip_total_qualified_bldgs,
    ROUND(AVG(percent_covered)   ,4)                                       AS zip_avg_pct_covered,
    ROUND(AVG(percent_qualified) ,4)                                       AS zip_avg_pct_qualified,
    SUM(number_of_panels_total)                                             AS zip_total_panels,
    SUM(kw_total)                                                           AS zip_total_kw,
    SUM(yearly_sunlight_kwh_total)                                          AS zip_total_kwh,
    SUM(carbon_offset_metric_tons)                                          AS zip_total_co2_offset_tons,
    SUM(existing_installs_count)                                            AS zip_current_installs,
    /* adjusted potential buildings & install gap */
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered/100.0)*(percent_qualified/100.0)
        )
      )
    )                                                                      AS zip_adj_potential_buildings,
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered/100.0)*(percent_qualified/100.0)
        )
      )
      - SUM(existing_installs_count)
    )                                                                      AS zip_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

/* ---------- Census-tract aggregation ---------- */
tract AS (
  SELECT
    state_name,
    /* core metrics */
    SUM(count_qualified)                                                   AS tract_total_qualified_bldgs,
    ROUND(AVG(percent_covered)   ,4)                                       AS tract_avg_pct_covered,
    ROUND(AVG(percent_qualified) ,4)                                       AS tract_avg_pct_qualified,
    SUM(number_of_panels_total)                                             AS tract_total_panels,
    SUM(kw_total)                                                           AS tract_total_kw,
    SUM(yearly_sunlight_kwh_total)                                          AS tract_total_kwh,
    SUM(carbon_offset_metric_tons)                                          AS tract_total_co2_offset_tons,
    SUM(existing_installs_count)                                            AS tract_current_installs,
    /* adjusted potential buildings & install gap */
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered/100.0)*(percent_qualified/100.0)
        )
      )
    )                                                                      AS tract_adj_potential_buildings,
    ROUND(
      SUM(
        SAFE_DIVIDE(
          count_qualified,
          (percent_covered/100.0)*(percent_qualified/100.0)
        )
      )
      - SUM(existing_installs_count)
    )                                                                      AS tract_install_gap
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

/* ---------- Combine both views ---------- */
SELECT
  COALESCE(z.state_name, t.state_name)                         AS state_name,

  /* ZIP-level columns */
  z.zip_total_qualified_bldgs,
  z.zip_avg_pct_covered,
  z.zip_avg_pct_qualified,
  z.zip_total_panels,
  z.zip_total_kw,
  z.zip_total_kwh,
  z.zip_total_co2_offset_tons,
  z.zip_current_installs,
  z.zip_adj_potential_buildings,
  z.zip_install_gap,

  /* Tract-level columns */
  t.tract_total_qualified_bldgs,
  t.tract_avg_pct_covered,
  t.tract_avg_pct_qualified,
  t.tract_total_panels,
  t.tract_total_kw,
  t.tract_total_kwh,
  t.tract_total_co2_offset_tons,
  t.tract_current_installs,
  t.tract_adj_potential_buildings,
  t.tract_install_gap

FROM zip z
FULL OUTER JOIN tract t
ON z.state_name = t.state_name

ORDER BY state_name;