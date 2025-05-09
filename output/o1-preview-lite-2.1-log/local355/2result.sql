WITH
total_races_per_year AS (
    SELECT r."year", COUNT(*) AS "total_races"
    FROM "races" r
    GROUP BY r."year"
),
driver_race_counts AS (
    SELECT res."driver_id", r."year", COUNT(DISTINCT res."race_id") AS "races_participated"
    FROM "results" res
    JOIN "races" r ON res."race_id" = r."race_id"
    GROUP BY res."driver_id", r."year"
),
drivers_with_missed_races AS (
    SELECT d."driver_id", d."year", tr."total_races" - d."races_participated" AS "races_missed"
    FROM driver_race_counts d
    JOIN total_races_per_year tr ON d."year" = tr."year"
    WHERE (tr."total_races" - d."races_participated") BETWEEN 1 AND 2
),
driver_missed_rounds AS (
    SELECT
        dr."driver_id",
        dr."year",
        MIN(r."round") AS "first_missed_round",
        MAX(r."round") AS "last_missed_round"
    FROM drivers_with_missed_races dr
    JOIN "races" r ON r."year" = dr."year"
    WHERE r."race_id" NOT IN (
        SELECT res."race_id"
        FROM "results" res
        WHERE res."driver_id" = dr."driver_id" AND res."race_id" IN (
            SELECT r2."race_id"
            FROM "races" r2
            WHERE r2."year" = dr."year"
        )
    )
    GROUP BY dr."driver_id", dr."year"
),
driver_team_before_after AS (
    SELECT
        dm."driver_id",
        dm."year",
        dm."first_missed_round",
        dm."last_missed_round",
        (
            SELECT res."constructor_id"
            FROM "results" res
            JOIN "races" r ON res."race_id" = r."race_id"
            WHERE res."driver_id" = dm."driver_id" AND r."year" = dm."year" AND r."round" < dm."first_missed_round"
            ORDER BY r."round" DESC
            LIMIT 1
        ) AS "team_before",
        (
            SELECT res."constructor_id"
            FROM "results" res
            JOIN "races" r ON res."race_id" = r."race_id"
            WHERE res."driver_id" = dm."driver_id" AND r."year" = dm."year" AND r."round" > dm."last_missed_round"
            ORDER BY r."round" ASC
            LIMIT 1
        ) AS "team_after"
    FROM driver_missed_rounds dm
),
drivers_switched_teams AS (
    SELECT
        dt."driver_id",
        dt."year",
        dt."first_missed_round",
        dt."last_missed_round"
    FROM driver_team_before_after dt
    WHERE dt."team_before" IS NOT NULL AND dt."team_after" IS NOT NULL AND dt."team_before" <> dt."team_after"
)
SELECT
    dt."year" AS "Year",
    AVG(dt."first_missed_round") AS "Average_First_Missed_Round",
    AVG(dt."last_missed_round") AS "Average_Last_Missed_Round"
FROM drivers_switched_teams dt
GROUP BY dt."year"
ORDER BY dt."year";