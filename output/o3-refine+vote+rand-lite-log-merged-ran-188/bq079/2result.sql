/* --------------------------------------------------------------------
   Highest‑acreage states (latest “EXPCURR” evaluation per state)
   –  Forestland  : COND_STATUS_CD = 1
   –  Timberland : COND_STATUS_CD = 1,  RESERVE_CD = 0,
                   SITE_PRODUCTIVITY_CLASS_CD between 1 and 6
   Acres = EXPANSION_FACTOR  ×  appropriate ADJ_FACTOR
           (MACR → ADJ_FACTOR_MACR,  SUBP → ADJ_FACTOR_SUBP;
            use 1 when the chosen factor ≤ 0)
------------------------------------------------------------------------ */

WITH latest_eval_per_state AS (            -- newest evaluation group that has type = 'EXPCURR'
    SELECT
        state_code,
        MAX(evaluation_group) AS evaluation_group
    FROM `bigquery-public-data.usfs_fia.population`
    WHERE evaluation_type = 'EXPCURR'
    GROUP BY state_code
),

pop AS (                                   -- population rows that belong to those latest groups
    SELECT p.*
    FROM `bigquery-public-data.usfs_fia.population` AS p
    JOIN latest_eval_per_state AS l
      ON p.state_code = l.state_code
     AND p.evaluation_group = l.evaluation_group
    WHERE p.evaluation_type = 'EXPCURR'
),

cond AS (                                  -- attach condition records
    SELECT
        p.state_code,
        p.evaluation_group,
        COALESCE(p.location_name, c.state_code_name) AS state_name,
        c.proportion_basis,
        p.expansion_factor,
        p.adjustment_factor_for_the_macroplot  AS adj_macr,
        p.adjustment_factor_for_the_subplot    AS adj_subp,
        c.condition_status_code                AS cond_status,
        c.reserved_status_code                 AS reserve_cd,
        c.site_productivity_class_code         AS spc_class
    FROM pop AS p
    JOIN `bigquery-public-data.usfs_fia.condition` AS c
      ON p.plot_sequence_number = c.plot_sequence_number
     AND p.inventory_year      = c.inventory_year
),

weighted AS (                              -- translate to adjusted acres for MACR / SUBP
    SELECT
        state_code,
        evaluation_group,
        state_name,
        CASE
            WHEN proportion_basis = 'MACR'
                 THEN expansion_factor * IF(adj_macr  > 0, adj_macr , 1)
            WHEN proportion_basis = 'SUBP'
                 THEN expansion_factor * IF(adj_subp  > 0, adj_subp , 1)
            ELSE 0
        END AS acres,
        cond_status,
        reserve_cd,
        spc_class
    FROM cond
    WHERE proportion_basis IN ('MACR','SUBP')
),

summed AS (                                -- aggregate by state (latest eval group already chosen)
    SELECT
        state_code,
        evaluation_group,
        MAX(state_name)                       AS state_name,
        SUM(CASE WHEN cond_status = 1                               THEN acres ELSE 0 END) AS forestland_acres,
        SUM(CASE WHEN cond_status = 1
                       AND reserve_cd = 0
                       AND spc_class BETWEEN 1 AND 6               THEN acres ELSE 0 END) AS timberland_acres
    FROM weighted
    GROUP BY state_code, evaluation_group
),

max_forest AS (                            -- state with most forestland acres
    SELECT *
    FROM summed
    ORDER BY forestland_acres DESC
    LIMIT 1
),

max_timber AS (                            -- state with most timberland acres
    SELECT *
    FROM summed
    ORDER BY timberland_acres DESC
    LIMIT 1
)

-- final two‑row result -------------------------------------------------
SELECT
    'FORESTLAND'        AS category,
    state_code,
    evaluation_group,
    state_name,
    forestland_acres    AS total_acres
FROM max_forest

UNION ALL

SELECT
    'TIMBERLAND'        AS category,
    state_code,
    evaluation_group,
    state_name,
    timberland_acres    AS total_acres
FROM max_timber;