WITH latest_evaluations AS (
  SELECT
    state_code,
    MAX(start_inventory_year) AS latest_year
  FROM
    `bigquery-public-data.usfs_fia.population_evaluation`
  GROUP BY
    state_code
),
latest_evaluation_sequences AS (
  SELECT
    pe.state_code,
    pe.evaluation_sequence_number
  FROM
    `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    JOIN latest_evaluations AS le
      ON pe.state_code = le.state_code
     AND pe.start_inventory_year = le.latest_year
),
condition_expansion AS (
  SELECT
    c.plot_sequence_number,
    le.state_code,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.condition_proportion_unadjusted,
    c.proportion_basis,
    ps.expansion_factor,
    ps.adjustment_factor_for_the_subplot,
    ps.adjustment_factor_for_the_macroplot,
    CASE
      WHEN c.proportion_basis = 'SUBP' THEN ps.adjustment_factor_for_the_subplot
      WHEN c.proportion_basis = 'MACR' THEN ps.adjustment_factor_for_the_macroplot
      ELSE 1.0
    END AS adjustment_factor,
    ps.expansion_factor * c.condition_proportion_unadjusted * CASE
      WHEN c.proportion_basis = 'SUBP' THEN ps.adjustment_factor_for_the_subplot
      WHEN c.proportion_basis = 'MACR' THEN ps.adjustment_factor_for_the_macroplot
      ELSE 1.0
    END AS area_estimate
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
    JOIN `bigquery-public-data.usfs_fia.population` AS p
      ON c.plot_sequence_number = p.plot_sequence_number
    JOIN latest_evaluation_sequences AS le
      ON p.evaluation_sequence_number = le.evaluation_sequence_number
    JOIN `bigquery-public-data.usfs_fia.population_stratum` AS ps
      ON p.stratum_sequence_number = ps.stratum_sequence_number
),
timberland_area AS (
  SELECT
    state_code,
    SUM(area_estimate) AS total_acres
  FROM
    condition_expansion
  WHERE
    condition_status_code = 1      -- Accessible forest land
    AND reserved_status_code = 0   -- Not reserved
    AND site_productivity_class_code IN (1, 2, 3, 4)   -- Productive sites
  GROUP BY
    state_code
),
forestland_area AS (
  SELECT
    state_code,
    SUM(area_estimate) AS total_acres
  FROM
    condition_expansion
  WHERE
    condition_status_code = 1   -- Accessible forest land
  GROUP BY
    state_code
),
state_names AS (
  SELECT DISTINCT
    state_code,
    location_name AS state_name
  FROM
    `bigquery-public-data.usfs_fia.population_evaluation`
)
SELECT
  t.state_code,
  'Timberland' AS evaluation_group,
  sn.state_name,
  ROUND(t.total_acres, 4) AS total_acres
FROM (
  SELECT
    state_code,
    total_acres,
    ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
  FROM
    timberland_area
) AS t
JOIN state_names AS sn
  ON t.state_code = sn.state_code
WHERE t.rn = 1
UNION ALL
SELECT
  f.state_code,
  'Forestland' AS evaluation_group,
  sn.state_name,
  ROUND(f.total_acres, 4) AS total_acres
FROM (
  SELECT
    state_code,
    total_acres,
    ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
  FROM
    forestland_area
) AS f
JOIN state_names AS sn
  ON f.state_code = sn.state_code
WHERE f.rn = 1;