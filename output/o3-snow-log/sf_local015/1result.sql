WITH helmet_status AS (
    SELECT
        c."case_id",
        c."motorcyclist_killed_count",
        CASE
            /* 1)  若至少出现一位摩托车相关当事方且其安全装备字段包含“helmet”且不包含“helmet not used / no helmet”字样，则视为“佩戴头盔” */
            WHEN EXISTS (
                     SELECT 1
                     FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES p
                     WHERE p."case_id" = c."case_id"
                       AND p."statewide_vehicle_type" ILIKE '%motorcycle%'
                       AND (   p."party_safety_equipment_1" ILIKE '%helmet%'
                            OR p."party_safety_equipment_2" ILIKE '%helmet%')
                       AND NOT (   p."party_safety_equipment_1" ILIKE '%helmet%not%used%'
                                OR p."party_safety_equipment_2" ILIKE '%helmet%not%used%'
                                OR p."party_safety_equipment_1" ILIKE '%no%helmet%'
                                OR p."party_safety_equipment_2" ILIKE '%no%helmet%')
                 )
            THEN 'helmet_used'
            /* 2)  其余摩托车碰撞均归为“未佩戴头盔” */
            ELSE 'helmet_not_used'
        END AS "helmet_flag"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
    WHERE c."motorcycle_collision" > 0          -- 仅统计摩托车碰撞
)

SELECT
    "helmet_flag",
    SUM("motorcyclist_killed_count")                             AS "total_motorcyclist_deaths",
    COUNT(*)                                                     AS "total_motorcycle_collisions",
    ROUND( SUM("motorcyclist_killed_count")
           / NULLIF(COUNT(*),0) * 100, 4)                        AS "fatality_rate_percent"
FROM helmet_status
GROUP BY "helmet_flag"
ORDER BY "helmet_flag";