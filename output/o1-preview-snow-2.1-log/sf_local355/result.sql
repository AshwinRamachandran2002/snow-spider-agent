WITH all_rounds AS (
    SELECT DISTINCT "year", "round"
    FROM F1.F1."RACES"
),
driver_races AS (
    SELECT DISTINCT r."driver_id", ra."year", ra."round"
    FROM F1.F1."RESULTS" r
    JOIN F1.F1."RACES" ra ON r."race_id" = ra."race_id"
),
driver_missed_rounds AS (
    SELECT dr."driver_id", ar."year", ar."round"
    FROM (SELECT DISTINCT "driver_id" FROM F1.F1."DRIVERS") dr
    JOIN all_rounds ar ON 1=1
    LEFT JOIN driver_races drr ON drr."driver_id" = dr."driver_id" AND drr."year" = ar."year" AND drr."round" = ar."round"
    WHERE drr."driver_id" IS NULL
),
driver_missed_counts AS (
    SELECT "driver_id", "year", COUNT(*) AS missed_races
    FROM driver_missed_rounds
    GROUP BY "driver_id", "year"
),
drivers_few_missed_races AS (
    SELECT "driver_id", "year"
    FROM driver_missed_counts
    WHERE missed_races < 3 AND missed_races > 0
),
driver_missed_rounds_summary AS (
    SELECT "driver_id", "year", MIN("round") AS first_missed_round, MAX("round") AS last_missed_round
    FROM driver_missed_rounds
    WHERE ("driver_id", "year") IN (SELECT "driver_id", "year" FROM drivers_few_missed_races)
    GROUP BY "driver_id", "year"
),
driver_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round"
    FROM F1.F1."DRIVES"
),
numbers AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY NULL) -1 AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),
driver_constructor_rounds AS (
    SELECT
        dd."driver_id",
        dd."year",
        dd."constructor_id",
        dd."first_round" + n.n AS "round"
    FROM driver_drives dd
    JOIN numbers n ON n.n <= dd."last_round" - dd."first_round"
),
constructors_before AS (
    SELECT DISTINCT dcr."driver_id", dcr."year", dcr."constructor_id"
    FROM driver_constructor_rounds dcr
    JOIN driver_missed_rounds_summary dmrs ON dcr."driver_id" = dmrs."driver_id" AND dcr."year" = dmrs."year"
    WHERE dcr."round" < dmrs.first_missed_round
),
constructors_after AS (
    SELECT DISTINCT dcr."driver_id", dcr."year", dcr."constructor_id"
    FROM driver_constructor_rounds dcr
    JOIN driver_missed_rounds_summary dmrs ON dcr."driver_id" = dmrs."driver_id" AND dcr."year" = dmrs."year"
    WHERE dcr."round" > dmrs.last_missed_round
),
drivers_switched_teams AS (
    SELECT cba."driver_id", cba."year"
    FROM (
        SELECT
            dmrs."driver_id",
            dmrs."year",
            COUNT(DISTINCT cb."constructor_id") AS count_before,
            COUNT(DISTINCT ca."constructor_id") AS count_after,
            SUM(CASE WHEN cb."constructor_id" = ca."constructor_id" THEN 1 ELSE 0 END) AS common_constructors
        FROM driver_missed_rounds_summary dmrs
        LEFT JOIN constructors_before cb ON dmrs."driver_id" = cb."driver_id" AND dmrs."year" = cb."year"
        LEFT JOIN constructors_after ca ON dmrs."driver_id" = ca."driver_id" AND dmrs."year" = ca."year"
        GROUP BY dmrs."driver_id", dmrs."year"
    ) cba
    WHERE cba.count_before > 0 AND cba.count_after > 0 AND cba.common_constructors = 0
),
qualified_drivers AS (
    SELECT DISTINCT ds."driver_id", ds."year", dmrs.first_missed_round, dmrs.last_missed_round
    FROM drivers_switched_teams ds
    JOIN driver_missed_rounds_summary dmrs ON ds."driver_id" = dmrs."driver_id" AND ds."year" = dmrs."year"
)
SELECT
    qd."year",
    ROUND(AVG(qd.first_missed_round), 4) AS "Average_First_Missed_Round",
    ROUND(AVG(qd.last_missed_round), 4) AS "Average_Last_Missed_Round"
FROM qualified_drivers qd
GROUP BY qd."year"
ORDER BY qd."year";