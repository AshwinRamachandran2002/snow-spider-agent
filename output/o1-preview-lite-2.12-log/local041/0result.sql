SELECT ROUND(
    (CAST((SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx' AND "health" = 'Good') AS FLOAT) /
     (SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx')) * 100
, 4) AS "percentage_good_trees_in_Bronx";