WITH fatalities AS (
    SELECT v."case_id", v."id",
        CASE
            WHEN LOWER(TRIM(v."victim_safety_equipment_1")) IN ('driver, motorcycle helmet used', 'passenger, motorcycle helmet used')
                 OR LOWER(TRIM(v."victim_safety_equipment_2")) IN ('driver, motorcycle helmet used', 'passenger, motorcycle helmet used') THEN 'Helmeted'
            WHEN LOWER(TRIM(v."victim_safety_equipment_1")) IN ('driver, motorcycle helmet not used', 'passenger, motorcycle helmet not used')
                 OR LOWER(TRIM(v."victim_safety_equipment_2")) IN ('driver, motorcycle helmet not used', 'passenger, motorcycle helmet not used') THEN 'Not Helmeted'
            ELSE 'Unknown'
        END AS "Helmet_use"
    FROM "victims" v
    JOIN "collisions" c ON v."case_id" = c."case_id"
    WHERE LOWER(v."victim_degree_of_injury") = 'killed'
        AND c."motorcycle_collision" = 1
)

SELECT
    "Helmet_use",
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fatalities WHERE "Helmet_use" IN ('Helmeted', 'Not Helmeted')), 4) AS "Percentage"
FROM fatalities
WHERE "Helmet_use" IN ('Helmeted', 'Not Helmeted')
GROUP BY "Helmet_use";