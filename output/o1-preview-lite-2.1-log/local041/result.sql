SELECT
    ROUND(100.0 * SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 4) AS "percentage_good_trees_in_Bronx"
FROM
    "trees"
WHERE
    "boroname" = 'Bronx';