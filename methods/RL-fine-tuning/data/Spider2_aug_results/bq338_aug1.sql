-- Task: Find the top 20 census tracts in the 36047 area that had over 1,000 residents in both 2011 and 2018, with the largest percentage increases in population between those years.
SELECT
    a.geo_id,
    a.total_pop AS pop_2011,
    b.total_pop AS pop_2018,
    ((b.total_pop - a.total_pop) / a.total_pop) * 100 AS population_change_percentage
FROM
    `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` a
JOIN
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` b
ON
    a.geo_id = b.geo_id
WHERE 
    a.total_pop > 1000
    AND b.total_pop > 1000
    AND a.geo_id LIKE '36047%'
ORDER BY 
    population_change_percentage DESC
LIMIT 20;