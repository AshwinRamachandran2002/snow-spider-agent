WITH condition_acres AS (
    SELECT
        peg.evaluation_group,
        pet.evaluation_type,
        c.condition_status_code,
        pe.evaluation_description,
        p.state_code,
        (p.expansion_factor *
         COALESCE(NULLIF(c.macroplot_proportion_unadjusted, 0), 1) *
         COALESCE(NULLIF(p.adjustment_factor_for_the_macroplot, 0), 1)) AS macroplot_acres,
        (p.expansion_factor *
         COALESCE(NULLIF(c.subplot_proportion_unadjusted, 0), 1) *
         COALESCE(NULLIF(p.adjustment_factor_for_the_subplot, 0), 1)) AS subplot_acres
    FROM `bigquery-public-data.usfs_fia.population` AS p
    JOIN `bigquery-public-data.usfs_fia.population_evaluation` AS pe
        ON p.evaluation_sequence_number = pe.evaluation_sequence_number
    JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` AS peg
        ON pe.evaluation_group_sequence_number = peg.evaluation_group_sequence_number
    JOIN `bigquery-public-data.usfs_fia.population_evaluation_type` AS pet
        ON pe.evaluation_sequence_number = pet.evaluation_sequence_number
    JOIN `bigquery-public-data.usfs_fia.condition` AS c
        ON p.plot_sequence_number = c.plot_sequence_number
    WHERE 2012 BETWEEN CAST(pe.start_inventory_year AS INT64) AND CAST(pe.end_inventory_year AS INT64)
)
SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    ROUND(macroplot_acres, 4) AS macroplot_acres,
    ROUND(subplot_acres, 4) AS subplot_acres
FROM (
    SELECT
        evaluation_group,
        evaluation_type,
        condition_status_code,
        evaluation_description,
        state_code,
        macroplot_acres,
        subplot_acres,
        ROW_NUMBER() OVER(PARTITION BY evaluation_group ORDER BY subplot_acres DESC) AS rn
    FROM condition_acres
)
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;