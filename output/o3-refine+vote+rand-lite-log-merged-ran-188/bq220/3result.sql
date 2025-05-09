WITH base AS (
  /*--------------------------------------------------------------------
  Select the records that belong to CURRENT‑EXPANSION evaluations
  and to accessible forest‑land conditions (condition_status_code = 1)
  for inventory years 2015‑2017.  Keep only the fields needed to build
  subplot and macroplot areas.
  --------------------------------------------------------------------*/
  SELECT
      p.plot_sequence_number,
      p.inventory_year               AS yr,
      p.state_code,
      c.state_code_name              AS state_name,
      p.expansion_factor,
      p.adjustment_factor_for_the_subplot  AS adj_subp,
      p.adjustment_factor_for_the_macroplot AS adj_macr,
      c.proportion_basis,
      c.condition_proportion_unadjusted    AS cond_prop
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON  c.plot_sequence_number = p.plot_sequence_number
    AND c.inventory_year       = p.inventory_year
    AND c.state_code           = p.state_code
  WHERE p.evaluation_type      = 'EXPCURR'
    AND c.condition_status_code = 1            -- Accessible forest land
    AND p.inventory_year IN (2015, 2016, 2017)
),
/*----------------------------------------------------------------------
Compute subplot and macroplot area for every record.  Null means this
record does not contribute to that plot type.
----------------------------------------------------------------------*/
areas AS (
  SELECT
      state_code,
      state_name,
      yr,
      CASE
        WHEN proportion_basis = 'SUBP' AND adj_subp > 0
             THEN expansion_factor * cond_prop * adj_subp
      END                                                    AS subplot_area,
      CASE
        WHEN proportion_basis = 'MACR' AND adj_macr > 0
             THEN expansion_factor * cond_prop * adj_macr
      END                                                    AS macroplot_area
  FROM base
),
/*----------------------------------------------------------------------
Average subplot and macroplot size by state & year
----------------------------------------------------------------------*/
avg_sz AS (
  SELECT
      state_code,
      state_name,
      yr,
      AVG(subplot_area)   AS avg_subplot_size,
      AVG(macroplot_area) AS avg_macroplot_size
  FROM areas
  GROUP BY state_code, state_name, yr
),
/*----------------------------------------------------------------------
For every year, rank the states by average subplot size
----------------------------------------------------------------------*/
rank_subplot AS (
  SELECT
      'Subplot'           AS plot_type,
      yr                  AS year,
      state_name          AS state,
      avg_subplot_size    AS avg_size,
      RANK() OVER (PARTITION BY yr ORDER BY avg_subplot_size DESC) AS rnk
  FROM avg_sz
  WHERE avg_subplot_size IS NOT NULL
),
/*----------------------------------------------------------------------
For every year, rank the states by average macroplot size
----------------------------------------------------------------------*/
rank_macro AS (
  SELECT
      'Macroplot'         AS plot_type,
      yr                  AS year,
      state_name          AS state,
      avg_macroplot_size  AS avg_size,
      RANK() OVER (PARTITION BY yr ORDER BY avg_macroplot_size DESC) AS rnk
  FROM avg_sz
  WHERE avg_macroplot_size IS NOT NULL
)
/*----------------------------------------------------------------------
Return the #1 state for each plot type (subplot / macroplot) and year
---------------------------------------------------------------------*/
SELECT plot_type, year, state, avg_size
FROM (
  SELECT * FROM rank_subplot WHERE rnk = 1
  UNION ALL
  SELECT * FROM rank_macro  WHERE rnk = 1
)
ORDER BY year, plot_type;