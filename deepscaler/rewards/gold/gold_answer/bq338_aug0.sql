-- Task: Identify the GEOIDs of census tracts within the '36047' area that had a total population greater than 1,000 in both 2011 and 2018, are among the top 20 census tracts with the largest percentage increase in total population from 2011 to 2018, and are also among the top 20 census tracts with the largest absolute increase in median income during the same period.

WITH population_change AS (
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
        AND b.geo_id LIKE '36047%'
    ORDER BY 
        population_change_percentage DESC
    LIMIT 20
),

acs_2018 AS (
    SELECT 
        geo_id, 
        median_income AS median_income_2018
    FROM 
        `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`  
    WHERE 
        geo_id LIKE '36047%'
        AND total_pop > 1000
),

acs_2011 AS (
    SELECT 
        geo_id, 
        median_income AS median_income_2011
    FROM 
        `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` 
    WHERE 
        geo_id LIKE '36047%'
        AND total_pop > 1000
),

acs_diff AS (
    SELECT
        a18.geo_id, 
        a18.median_income_2018, 
        a11.median_income_2011,
        (a18.median_income_2018 - a11.median_income_2011) AS median_income_diff
    FROM 
        acs_2018 a18
    JOIN 
        acs_2011 a11
        ON a18.geo_id = a11.geo_id
    WHERE 
        (a18.median_income_2018 - a11.median_income_2011) IS NOT NULL
    ORDER BY 
        (a18.median_income_2018 - a11.median_income_2011) DESC
    LIMIT 20
),

common_geoids AS (
    SELECT population_change.geo_id
    FROM population_change
    JOIN acs_diff ON population_change.geo_id = acs_diff.geo_id
)

SELECT geo_id FROM common_geoids;