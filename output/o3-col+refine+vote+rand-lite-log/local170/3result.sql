/*  States where BOTH male and female cohorts have at least one legislator
    still in office on 31-December of years 0, 2, 4, 6, 8 and 10 after each
    member’s first term-start                                               */

WITH first_start AS (            -- earliest term-start for every legislator
    SELECT "id_bioguide",
           MIN("term_start") AS "first_start"
    FROM   "legislators_terms"
    GROUP  BY "id_bioguide"
),
/* Build the six check-point dates (all on 31-Dec) for each legislator   */
checkpoints AS (
    SELECT  fs."id_bioguide",
            DATE( STRFTIME('%Y', fs."first_start")                       || '-12-31') AS "d0",
            DATE( (CAST(STRFTIME('%Y', fs."first_start") AS INTEGER)+ 2) || '-12-31') AS "d2",
            DATE( (CAST(STRFTIME('%Y', fs."first_start") AS INTEGER)+ 4) || '-12-31') AS "d4",
            DATE( (CAST(STRFTIME('%Y', fs."first_start") AS INTEGER)+ 6) || '-12-31') AS "d6",
            DATE( (CAST(STRFTIME('%Y', fs."first_start") AS INTEGER)+ 8) || '-12-31') AS "d8",
            DATE( (CAST(STRFTIME('%Y', fs."first_start") AS INTEGER)+10) || '-12-31') AS "d10"
    FROM   first_start fs
),
/* Flag whether each legislator is serving on every checkpoint date      */
per_leg AS (
    SELECT  l."id_bioguide",
            l."gender",
            t0."state",

            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d0" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r0",
            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d2" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r2",
            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d4" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r4",
            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d6" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r6",
            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d8" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r8",
            CASE WHEN EXISTS (SELECT 1 FROM "legislators_terms" tt
                              WHERE tt."id_bioguide" = l."id_bioguide"
                                AND  cp."d10" BETWEEN tt."term_start" AND tt."term_end") THEN 1 ELSE 0 END AS "r10"

    FROM    "legislators"        l
    JOIN    first_start          fs  ON fs."id_bioguide" = l."id_bioguide"
    JOIN    checkpoints          cp  ON cp."id_bioguide" = l."id_bioguide"
    JOIN    "legislators_terms"  t0  ON t0."id_bioguide" = fs."id_bioguide"
                                    AND t0."term_start"  = fs."first_start"
),
/* Does a gender cohort in a state keep ≥1 member at *every* checkpoint? */
by_state_gender AS (
    SELECT  "state",
            "gender",
            CASE WHEN SUM("r0")  > 0
               AND  SUM("r2")  > 0
               AND  SUM("r4")  > 0
               AND  SUM("r6")  > 0
               AND  SUM("r8")  > 0
               AND  SUM("r10") > 0
                 THEN 1 ELSE 0 END AS "all_kept"
    FROM    per_leg
    GROUP   BY "state", "gender"
)
/*  States where both male and female cohorts satisfy the rule           */
SELECT  "state"
FROM    by_state_gender
WHERE   "all_kept" = 1
GROUP   BY "state"
HAVING  COUNT(DISTINCT "gender") = 2          -- both M & F succeed
ORDER BY "state";