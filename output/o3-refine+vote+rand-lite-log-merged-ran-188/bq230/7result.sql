SELECT
  state_name,
  SUM( CASE 
          WHEN commodity_desc = 'CORN' 
               AND group_desc = 'FIELD CROPS'
               AND unit_desc = 'BU'          -- corn must be in bushels
          THEN value 
       END ) AS corn_production_bushels_2022,
  SUM( CASE 
          WHEN commodity_desc = 'MUSHROOMS' 
               AND group_desc = 'HORTICULTURE'
          THEN value 
       END ) AS mushroom_production_2022
FROM `bigquery-public-data.usda_nass_agriculture.crops`
WHERE year = 2022
  AND agg_level_desc = 'STATE'
  AND statisticcat_desc = 'PRODUCTION'
  AND value IS NOT NULL
  AND (
        (commodity_desc = 'CORN'      AND group_desc = 'FIELD CROPS'   AND unit_desc = 'BU')
     OR (commodity_desc = 'MUSHROOMS' AND group_desc = 'HORTICULTURE')
      )
GROUP BY state_name
ORDER BY state_name;