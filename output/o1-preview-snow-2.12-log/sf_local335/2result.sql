WITH
constructor_groups AS (
    SELECT
        c."constructor_id",
        CASE
            WHEN c."constructor_ref" = 'minardi' THEN 'Minardi'
            WHEN c."constructor_ref" = 'hrt' THEN 'HRT'
            WHEN c."constructor_ref" IN ('virgin', 'marussia') THEN 'Marussia/Virgin'
            WHEN c."constructor_ref" = 'caterham' THEN 'Caterham'
            WHEN c."constructor_ref" = 'super_aguri' THEN 'Super Aguri'
            ELSE c."name"
        END AS "Constructor_Group"
    FROM F1.F1.CONSTRUCTORS c
),
season_points AS (
    SELECT
        res."constructor_id",
        r."year",
        SUM(res."points") AS "total_points"
    FROM F1.F1.RESULTS res
    JOIN F1.F1.RACES r ON res."race_id" = r."race_id"
    WHERE r."year" >= 2001
    GROUP BY res."constructor_id", r."year"
),
min_season_points AS (
    SELECT
        sp."year",
        MIN(sp."total_points") AS "min_total_points"
    FROM season_points sp
    GROUP BY sp."year"
),
constructors_with_min_points AS (
    SELECT
        sp."constructor_id",
        sp."year",
        sp."total_points"
    FROM season_points sp
    JOIN min_season_points msp
        ON sp."year" = msp."year" AND sp."total_points" = msp."min_total_points"
)
SELECT
    cg."Constructor_Group" AS "Constructor",
    COUNT(*) AS "Number_of_Seasons_With_Fewest_Points"
FROM constructors_with_min_points cwp
JOIN constructor_groups cg
    ON cwp."constructor_id" = cg."constructor_id"
GROUP BY cg."Constructor_Group"
ORDER BY "Number_of_Seasons_With_Fewest_Points" DESC NULLS LAST, cg."Constructor_Group"
LIMIT 5;