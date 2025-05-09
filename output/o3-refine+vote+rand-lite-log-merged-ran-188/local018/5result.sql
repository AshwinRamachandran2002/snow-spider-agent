WITH collisions_year AS (
    -- keep only 2011 and 2021 crashes together with their PCF violation category
    SELECT ci.db_year,
           c.pcf_violation_category
    FROM collisions  AS c
    JOIN case_ids    AS ci ON ci.case_id = c.case_id
    WHERE ci.db_year IN (2011, 2021)
),
top_cat AS (
    -- find the most common PCF‑violation category in 2021
    SELECT pcf_violation_category AS category
    FROM   collisions_year
    WHERE  db_year = 2021
      AND  pcf_violation_category IS NOT NULL
    GROUP  BY pcf_violation_category
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
year_stats AS (
    -- for each of the two years, count how many crashes belong to that top category
    -- and how many crashes occurred in total
    SELECT cy.db_year,
           SUM(CASE WHEN cy.pcf_violation_category = tc.category THEN 1 ELSE 0 END) AS category_count,
           COUNT(*)                                                               AS total_count
    FROM   collisions_year AS cy
    CROSS  JOIN top_cat     AS tc
    GROUP  BY cy.db_year
)
-- compute the decrease in percentage‑points from 2011 to 2021
SELECT ROUND(
           (SELECT 100.0 * category_count / total_count FROM year_stats WHERE db_year = 2011) -
           (SELECT 100.0 * category_count / total_count FROM year_stats WHERE db_year = 2021)
       , 4) AS percentage_point_decrease;