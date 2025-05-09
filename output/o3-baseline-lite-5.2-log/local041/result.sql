SELECT
    100.0 * SUM(CASE WHEN "health" = 'Good' THEN 1 ELSE 0 END) / COUNT(*) AS percentage_good_bronx_trees
FROM
    "trees"
WHERE
    "boroname" = 'Bronx';