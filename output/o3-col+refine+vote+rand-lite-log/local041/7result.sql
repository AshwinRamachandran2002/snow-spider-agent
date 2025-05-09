SELECT ROUND(
           100.0 * 
           (SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx' AND "health" = 'Good')
           /
           (SELECT COUNT(*) FROM "trees" WHERE "boroname" = 'Bronx'),
           4
       ) AS "percent_good_in_bronx";