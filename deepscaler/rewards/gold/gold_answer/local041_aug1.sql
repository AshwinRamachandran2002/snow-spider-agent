-- Task: List the number of trees in the Bronx for each health status.

SELECT
    "health",
    COUNT(*) AS "num_trees"
FROM
    "trees"
WHERE
    "boroname" = 'Bronx'
GROUP BY
    "health";