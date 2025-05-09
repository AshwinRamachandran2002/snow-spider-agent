-- States with the largest average subplot‑ and macroplot‑sizes
-- (evaluation_type = 'EXPCURR'  AND  condition_status_code = 1)
-- for inventory years 2015‑2017
WITH joined AS (
  SELECT
    p.inventory_year                                    AS yr ,
    p.state_code                                        AS st ,
    c.proportion_basis                                  AS basis ,
    c.condition_proportion_unadjusted                   AS prop_unadj ,
    p.expansion_factor                                  AS exp_fac ,
    p.adjustment_factor_for_the_subplot                 AS adj_subp ,
    p.adjustment_factor_for_the_macroplot               AS adj_macr
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year        = c.inventory_year
   AND p.state_code            = c.state_code
  WHERE p.evaluation_type      = 'EXPCURR'
    AND c.condition_status_code = 1
    AND p.inventory_year IN (2015,2016,2017)
),

-- ─────────────────────────────────────────  average subplot size  ─────────────────────────────────────────
sub_avg AS (
  SELECT
    yr ,
    st ,
    AVG( exp_fac * prop_unadj * adj_subp ) AS avg_size
  FROM joined
  WHERE basis = 'SUBP' AND adj_subp > 0
  GROUP BY yr , st
),

sub_top AS (
  SELECT
    'SUBPLOT'             AS plot_type ,
    yr                    AS year ,
    st                    AS state_code ,
    avg_size
  FROM sub_avg
  QUALIFY RANK() OVER (PARTITION BY yr ORDER BY avg_size DESC) = 1
),

-- ─────────────────────────────────────────  average macroplot size  ───────────────────────────────────────
mac_avg AS (
  SELECT
    yr ,
    st ,
    AVG( exp_fac * prop_unadj * adj_macr ) AS avg_size
  FROM joined
  WHERE basis = 'MACR' AND adj_macr > 0
  GROUP BY yr , st
),

mac_top AS (
  SELECT
    'MACROPLOT'           AS plot_type ,
    yr                    AS year ,
    st                    AS state_code ,
    avg_size
  FROM mac_avg
  QUALIFY RANK() OVER (PARTITION BY yr ORDER BY avg_size DESC) = 1
)

-- ─────────────────────────────────────────  final answer  ─────────────────────────────────────────
SELECT *
FROM (
  SELECT * FROM sub_top
  UNION ALL
  SELECT * FROM mac_top
)
ORDER BY year , plot_type;