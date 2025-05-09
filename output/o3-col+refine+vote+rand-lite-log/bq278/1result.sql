/* -----------------------------------------------------------
   State-level solar-potential comparison
   – Postal-code vs. Census-tract granularity
------------------------------------------------------------ */
WITH postal AS (
  SELECT
    state_name,
    /* core sums / averages */
    SUM(count_qualified)                        AS qual_pc,            -- total buildings available
    AVG(percent_covered)                        AS pct_cov_pc,         -- avg % of Google-maps area covered
    AVG(percent_qualified)                      AS pct_suit_pc,        -- avg % of that area suitable
    SUM(number_of_panels_total)                 AS panels_pc,          -- total potential panel count
    SUM(kw_total)                               AS kw_pc,              -- total kW capacity
    SUM(yearly_sunlight_kwh_total)              AS kwh_pc,             -- energy generation potential
    SUM(carbon_offset_metric_tons)              AS co2_pc,             -- CO₂ offset (tons)
    SUM(existing_installs_count)                AS installs_pc,        -- current installs

    /* installation gap = adjusted potential − current installs */
    ROUND(
      SUM(count_qualified) /
      (AVG(percent_covered)/100.0 * AVG(percent_qualified)/100.0)
      - SUM(existing_installs_count)
    )                                           AS gap_pc
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_postal_code`
  GROUP BY state_name
),

tract AS (
  SELECT
    state_name,
    SUM(count_qualified)                        AS qual_ct,
    AVG(percent_covered)                        AS pct_cov_ct,
    AVG(percent_qualified)                      AS pct_suit_ct,
    SUM(number_of_panels_total)                 AS panels_ct,
    SUM(kw_total)                               AS kw_ct,
    SUM(yearly_sunlight_kwh_total)              AS kwh_ct,
    SUM(carbon_offset_metric_tons)              AS co2_ct,
    SUM(existing_installs_count)                AS installs_ct,
    ROUND(
      SUM(count_qualified) /
      (AVG(percent_covered)/100.0 * AVG(percent_qualified)/100.0)
      - SUM(existing_installs_count)
    )                                           AS gap_ct
  FROM `bigquery-public-data.sunroof_solar.solar_potential_by_censustract`
  GROUP BY state_name
)

SELECT
  COALESCE(p.state_name, t.state_name)          AS state_name,

  /* ---- postal-code level fields ---- */
  p.qual_pc          AS total_buildings_pc,
  p.pct_cov_pc       AS avg_pct_covered_pc,
  p.pct_suit_pc      AS avg_pct_suitable_pc,
  p.panels_pc        AS total_panels_pc,
  p.kw_pc            AS total_kw_pc,
  p.kwh_pc           AS total_kwh_pc,
  p.co2_pc           AS total_co2_offset_tons_pc,
  p.installs_pc      AS current_installs_pc,
  p.gap_pc           AS install_gap_pc,

  /* ---- census-tract level fields ---- */
  t.qual_ct          AS total_buildings_ct,
  t.pct_cov_ct       AS avg_pct_covered_ct,
  t.pct_suit_ct      AS avg_pct_suitable_ct,
  t.panels_ct        AS total_panels_ct,
  t.kw_ct            AS total_kw_ct,
  t.kwh_ct           AS total_kwh_ct,
  t.co2_ct           AS total_co2_offset_tons_ct,
  t.installs_ct      AS current_installs_ct,
  t.gap_ct           AS install_gap_ct

FROM postal p
FULL JOIN tract t
USING (state_name)
ORDER BY state_name;