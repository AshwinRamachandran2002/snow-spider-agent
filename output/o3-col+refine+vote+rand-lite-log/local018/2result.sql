WITH top_category AS (          -- most common PCF category in 2021
    SELECT "pcf_violation_category" AS cat
    FROM   "collisions"
    WHERE  substr("collision_date",1,4) = '2021'
    GROUP  BY cat
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
year_totals AS (                -- total collisions in 2011 & 2021
    SELECT substr("collision_date",1,4) AS yr,
           COUNT(*) AS total_cnt
    FROM   "collisions"
    WHERE  substr("collision_date",1,4) IN ('2011','2021')
    GROUP  BY yr
),
cat_totals AS (                 -- collisions in the top category for each year
    SELECT substr("collision_date",1,4) AS yr,
           COUNT(*) AS cat_cnt
    FROM   "collisions", top_category
    WHERE  substr("collision_date",1,4) IN ('2011','2021')
      AND  "pcf_violation_category" = top_category.cat
    GROUP  BY yr
)
SELECT ROUND(
         (SELECT cat_cnt*100.0/total_cnt 
          FROM cat_totals JOIN year_totals USING(yr) 
          WHERE yr='2021')
         -
         (SELECT cat_cnt*100.0/total_cnt 
          FROM cat_totals JOIN year_totals USING(yr) 
          WHERE yr='2011')
       , 2) AS "percentage_point_decrease";