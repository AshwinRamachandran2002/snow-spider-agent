WITH "DRIVES_CTE" AS (      -- keep the drives we will evaluate
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round"
    FROM F1.F1.DRIVES
    WHERE "first_round" IS NOT NULL
      AND "last_round"  IS NOT NULL
),

/* pair every drive with the very next drive that same driver has in the
   same season so we can look for a gap between them                        */
"PAIRED_DRIVES" AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id"                                               AS "before_constructor_id",
        "last_round"                                                   AS "before_last_round",
        LEAD("constructor_id") OVER (PARTITION BY "driver_id","year"
                                     ORDER BY "first_round")           AS "after_constructor_id",
        LEAD("first_round")     OVER (PARTITION BY "driver_id","year"
                                     ORDER BY "first_round")           AS "after_first_round"
    FROM "DRIVES_CTE"
),

/* choose only the gaps that meet the question’s requirements             */
"QUALIFIED_GAPS" AS (
    SELECT
        "driver_id",
        "year",
        ("before_last_round" + 1)                         AS "first_missed_round",
        ("after_first_round"  - 1)                        AS "last_missed_round",
        ("after_first_round" - "before_last_round" - 1)   AS "missed_race_count"
    FROM "PAIRED_DRIVES"
    WHERE "after_first_round" IS NOT NULL
      AND "after_constructor_id" IS NOT NULL
      AND "after_constructor_id" <> "before_constructor_id"            -- switched teams
      AND ("after_first_round" - "before_last_round" - 1) BETWEEN 1 AND 2 -- missed < 3 races
)

/* overall averages (not grouped by year)                                 */
SELECT
    ROUND(AVG("first_missed_round"), 4) AS "avg_first_round_missed",
    ROUND(AVG("last_missed_round"), 4)  AS "avg_last_round_missed"
FROM "QUALIFIED_GAPS";