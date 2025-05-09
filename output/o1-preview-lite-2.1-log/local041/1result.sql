SELECT
  ROUND(100.0 * (
    SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx' AND "health" = 'Good'
  ) / (
    SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx'
  ), 4) AS "percentage_good_trees_in_Bronx";