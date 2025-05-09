SELECT 
    CASE 
        WHEN UPPER(TRIM(v."victim_safety_equipment_1")) = 'DRIVER, MOTORCYCLE HELMET USED' 
             OR UPPER(TRIM(v."victim_safety_equipment_2")) = 'DRIVER, MOTORCYCLE HELMET USED' THEN 'Helmeted'
        WHEN UPPER(TRIM(v."victim_safety_equipment_1")) = 'DRIVER, MOTORCYCLE HELMET NOT USED' 
             OR UPPER(TRIM(v."victim_safety_equipment_2")) = 'DRIVER, MOTORCYCLE HELMET NOT USED' THEN 'Not Helmeted'
    END AS Helmet_use,
    ROUND(
        COUNT(*) * 100.0 / (
            SELECT COUNT(*)
            FROM "victims" v2
            JOIN "collisions" c2 ON v2."case_id" = c2."case_id"
            WHERE
                c2."motorcycle_collision" = 1
                AND UPPER(TRIM(v2."victim_degree_of_injury")) = 'KILLED'
                AND UPPER(TRIM(v2."victim_role")) = 'DRIVER'
                AND (
                    UPPER(TRIM(v2."victim_safety_equipment_1")) IN ('DRIVER, MOTORCYCLE HELMET USED', 'DRIVER, MOTORCYCLE HELMET NOT USED')
                    OR UPPER(TRIM(v2."victim_safety_equipment_2")) IN ('DRIVER, MOTORCYCLE HELMET USED', 'DRIVER, MOTORCYCLE HELMET NOT USED')
                )
        ), 4
    ) AS Percentage
FROM "victims" v
JOIN "collisions" c ON v."case_id" = c."case_id"
WHERE 
    c."motorcycle_collision" = 1
    AND UPPER(TRIM(v."victim_degree_of_injury")) = 'KILLED'
    AND UPPER(TRIM(v."victim_role")) = 'DRIVER'
    AND (
        UPPER(TRIM(v."victim_safety_equipment_1")) IN ('DRIVER, MOTORCYCLE HELMET USED', 'DRIVER, MOTORCYCLE HELMET NOT USED')
        OR UPPER(TRIM(v."victim_safety_equipment_2")) IN ('DRIVER, MOTORCYCLE HELMET USED', 'DRIVER, MOTORCYCLE HELMET NOT USED')
    )
GROUP BY Helmet_use;