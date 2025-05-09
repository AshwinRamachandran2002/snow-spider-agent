SELECT
  'vehicle code violation' AS "Cause",
  ROUND(
    (
      (
        SELECT COUNT(*)::FLOAT
        FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
        WHERE SUBSTRING("collision_date", 1, 4) = '2011' AND "primary_collision_factor" = 'vehicle code violation'
      ) * 100.0 /
      (
        SELECT COUNT(*)::FLOAT
        FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
        WHERE SUBSTRING("collision_date", 1, 4) = '2011'
      )
    )
    -
    (
      (
        SELECT COUNT(*)::FLOAT
        FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
        WHERE SUBSTRING("collision_date", 1, 4) = '2021' AND "primary_collision_factor" = 'vehicle code violation'
      ) * 100.0 /
      (
        SELECT COUNT(*)::FLOAT
        FROM "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
        WHERE SUBSTRING("collision_date", 1, 4) = '2021'
      )
    )
  , 4) AS "Percentage_Decrease"
;