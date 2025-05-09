WITH "BALL_DATA" AS (          --  every delivery with runs off the bat & extras
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."ball_id",
        bb."striker",
        bb."non_striker",
        COALESCE(bs."runs_scored", 0)  AS "runs_scored",
        COALESCE(er."extra_runs", 0)   AS "extra_runs"
    FROM  IPL.IPL.BALL_BY_BALL  bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"  = bs."match_id"
           AND bb."innings_no"= bs."innings_no"
           AND bb."over_id"   = bs."over_id"
           AND bb."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS  er
           ON  bb."match_id"  = er."match_id"
           AND bb."innings_no"= er."innings_no"
           AND bb."over_id"   = er."over_id"
           AND bb."ball_id"   = er."ball_id"
),

/*  Partnership totals for every (match, pair)  */
"PARTNERSHIP" AS (
    SELECT
        "match_id",
        LEAST  ("striker","non_striker")  AS "p_low",    -- smaller id
        GREATEST("striker","non_striker") AS "p_high",   -- larger  id
        SUM("runs_scored" + "extra_runs")                                         AS "partnership_runs",
        SUM(CASE WHEN "striker" = LEAST  ("striker","non_striker")  THEN "runs_scored" ELSE 0 END)  AS "runs_low",
        SUM(CASE WHEN "striker" = GREATEST("striker","non_striker") THEN "runs_scored" ELSE 0 END)  AS "runs_high"
    FROM "BALL_DATA"
    GROUP BY "match_id",
             LEAST  ("striker","non_striker"),
             GREATEST("striker","non_striker")
),

/*  Maximum-run partnership(s) for every match  */
"MAX_PARTNERSHIP_PER_MATCH" AS (
    SELECT
        "match_id",
        MAX("partnership_runs") AS "max_partnership_runs"
    FROM "PARTNERSHIP"
    GROUP BY "match_id"
),

"TOP_PARTNERSHIPS" AS (
    SELECT
        p."match_id",
        p."p_low",
        p."p_high",
        p."runs_low",
        p."runs_high",
        p."partnership_runs"
    FROM "PARTNERSHIP"           p
    JOIN "MAX_PARTNERSHIP_PER_MATCH" m
      ON p."match_id"          = m."match_id"
     AND p."partnership_runs"  = m."max_partnership_runs"   -- keep only the top ones
)

/*  Final formatting: decide player1 / player2 ordering rules  */
SELECT
    "match_id",

    CASE
        WHEN "runs_low" > "runs_high"                                     THEN "p_low"
        WHEN "runs_low" < "runs_high"                                     THEN "p_high"
        WHEN "runs_low" = "runs_high" AND "p_low" > "p_high"              THEN "p_low"
        ELSE                                                                  "p_high"
    END  AS "player1_id",

    CASE
        WHEN "runs_low" > "runs_high"                                     THEN "runs_low"
        WHEN "runs_low" < "runs_high"                                     THEN "runs_high"
        WHEN "runs_low" = "runs_high" AND "p_low" > "p_high"              THEN "runs_low"
        ELSE                                                                  "runs_high"
    END  AS "player1_runs",

    CASE
        WHEN "runs_low" > "runs_high"                                     THEN "p_high"
        WHEN "runs_low" < "runs_high"                                     THEN "p_low"
        WHEN "runs_low" = "runs_high" AND "p_low" > "p_high"              THEN "p_high"
        ELSE                                                                  "p_low"
    END  AS "player2_id",

    CASE
        WHEN "runs_low" > "runs_high"                                     THEN "runs_high"
        WHEN "runs_low" < "runs_high"                                     THEN "runs_low"
        WHEN "runs_low" = "runs_high" AND "p_low" > "p_high"              THEN "runs_high"
        ELSE                                                                  "runs_low"
    END  AS "player2_runs",

    "partnership_runs"   AS "total_partnership_runs"
FROM   "TOP_PARTNERSHIPS"
ORDER BY "match_id";