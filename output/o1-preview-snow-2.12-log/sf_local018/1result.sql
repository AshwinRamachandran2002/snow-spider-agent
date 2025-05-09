SELECT
    'speeding' AS "Cause",
    ROUND(
        (
            (
                (
                    (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                     WHERE "collision_date" LIKE '2021%'
                     AND "pcf_violation_category" = 'speeding')::FLOAT
                    /
                    (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                     WHERE "collision_date" LIKE '2021%'
                     AND "pcf_violation_category" IS NOT NULL
                     AND "pcf_violation_category" <> '')::FLOAT
                )
                -
                (
                    (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                     WHERE "collision_date" LIKE '2011%'
                     AND "pcf_violation_category" = 'speeding')::FLOAT
                    /
                    (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                     WHERE "collision_date" LIKE '2011%'
                     AND "pcf_violation_category" IS NOT NULL
                     AND "pcf_violation_category" <> '')::FLOAT
                )
            )
            /
            (
                (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                 WHERE "collision_date" LIKE '2011%'
                 AND "pcf_violation_category" = 'speeding')::FLOAT
                /
                (SELECT COUNT(*) FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS
                 WHERE "collision_date" LIKE '2011%'
                 AND "pcf_violation_category" IS NOT NULL
                 AND "pcf_violation_category" <> '')::FLOAT
            )
        ) * 100, 4
    ) AS "Percentage_Decrease"
;