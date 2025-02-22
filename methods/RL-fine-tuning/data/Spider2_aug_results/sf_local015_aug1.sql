-- Task: Please calculate, separately for motorcycle collisions involving riders who were wearing helmets and those who were not wearing helmets, the total number of motorcyclist fatalities and the total number of collisions involving that group.

WITH BASE AS (
    SELECT 
        COL."case_id" AS "case_id",
        COL."motorcyclist_killed_count" AS "motorcyclist_killed_count",
        CASE 
            WHEN PARTY."party_safety_equipment_1" = 'driver, motorcycle helmet used' 
                 OR PARTY."party_safety_equipment_2" = 'driver, motorcycle helmet used' 
                 OR PARTY."party_safety_equipment_1" = 'passenger, motorcycle helmet used' 
                 OR PARTY."party_safety_equipment_2" = 'passenger, motorcycle helmet used' 
            THEN 1 
            ELSE 0 
        END AS "helmet_used",
        CASE 
            WHEN PARTY."party_safety_equipment_1" = 'driver, motorcycle helmet not used' 
                 OR PARTY."party_safety_equipment_2" = 'driver, motorcycle helmet not used' 
                 OR PARTY."party_safety_equipment_1" = 'passenger, motorcycle helmet not used' 
                 OR PARTY."party_safety_equipment_2" = 'passenger, motorcycle helmet not used' 
            THEN 1 
            ELSE 0 
        END AS "helmet_not_used"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS COL
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES PARTY
        ON COL."case_id" = PARTY."case_id"
    WHERE 
        COL."motorcycle_collision" = '1'
        AND PARTY."party_age" IS NOT NULL
    GROUP BY 
        COL."case_id", 
        COL."motorcyclist_killed_count", 
        PARTY."party_safety_equipment_1", 
        PARTY."party_safety_equipment_2"
)
SELECT 
    SUM(CASE WHEN "helmet_used" = 1 THEN "motorcyclist_killed_count" ELSE 0 END) AS "total_fatalities_helmet_used",
    COUNT(DISTINCT CASE WHEN "helmet_used" = 1 THEN "case_id" END) AS "total_collisions_helmet_used",
    SUM(CASE WHEN "helmet_not_used" = 1 THEN "motorcyclist_killed_count" ELSE 0 END) AS "total_fatalities_helmet_not_used",
    COUNT(DISTINCT CASE WHEN "helmet_not_used" = 1 THEN "case_id" END) AS "total_collisions_helmet_not_used"
FROM 
    BASE;