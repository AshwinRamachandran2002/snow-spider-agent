WITH sizes AS (
     SELECT
       CASE WHEN c.proportion_basis = 'SUBP' THEN 'subplot'
            WHEN c.proportion_basis = 'MACR' THEN 'macroplot' END AS Type_of_Plot,
       p.plot_inventory_year AS Year,
       p.plot_state_code_name AS State,
       (ps.expansion_factor * c.condition_proportion_unadjusted *
          CASE WHEN c.proportion_basis = 'SUBP' THEN ps.adjustment_factor_for_the_subplot
               WHEN c.proportion_basis = 'MACR' THEN ps.adjustment_factor_for_the_macroplot END) AS Size
     FROM `bigquery-public-data.usfs_fia.plot` p
     JOIN `bigquery-public-data.usfs_fia.condition` c
       ON p.plot_sequence_number = c.plot_sequence_number
     JOIN `bigquery-public-data.usfs_fia.population_stratum_assign` psa
       ON p.plot_sequence_number = psa.plot_sequence_number
     JOIN `bigquery-public-data.usfs_fia.population_stratum` ps
       ON psa.stratum_sequence_number = ps.stratum_sequence_number
     WHERE p.plot_inventory_year IN (2015, 2016, 2017)
       AND c.condition_status_code = 1
       AND c.proportion_basis IN ('SUBP', 'MACR')
       AND ( (c.proportion_basis = 'SUBP' AND ps.adjustment_factor_for_the_subplot > 0)
           OR (c.proportion_basis = 'MACR' AND ps.adjustment_factor_for_the_macroplot > 0) )
   ),
   avg_sizes AS (
     SELECT
       Type_of_Plot,
       Year,
       State,
       AVG(Size) AS Average_Size
     FROM sizes
     GROUP BY Type_of_Plot, Year, State
   )
   SELECT Type_of_Plot, Year, State, Average_Size
   FROM (
     SELECT
       avg_sizes.*,
       ROW_NUMBER() OVER (PARTITION BY Type_of_Plot, Year ORDER BY Average_Size DESC) AS rn
     FROM avg_sizes
   )
   WHERE rn = 1
   ORDER BY Type_of_Plot, Year;