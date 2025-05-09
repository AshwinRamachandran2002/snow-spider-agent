WITH ball AS (
    /* one record per ball with the two batsmen stored in ascending-id order */
    SELECT  bb."match_id",
            CASE WHEN bb."striker" < bb."non_striker" THEN bb."striker" ELSE bb."non_striker" END AS "p1",
            CASE WHEN bb."striker" < bb."non_striker" THEN bb."non_striker" ELSE bb."striker" END AS "p2",
            bb."striker",
            COALESCE(bs."runs_scored",0)              AS "runs_scored",
            COALESCE(er."extra_runs",0)               AS "extra_runs"
    FROM   "ball_by_ball"  AS bb
    LEFT   JOIN "batsman_scored" AS bs
           USING ("match_id","over_id","ball_id","innings_no")
    LEFT   JOIN "extra_runs"    AS er
           USING ("match_id","over_id","ball_id","innings_no")
),  /* aggregate runs for every (unordered) batting pair in a match */
pair_runs AS (
    SELECT  "match_id",
            "p1","p2",
            SUM("runs_scored" + "extra_runs")                                             AS "partnership_runs",
            SUM(CASE WHEN "striker" = "p1" THEN "runs_scored" ELSE 0 END)                 AS "p1_runs",
            SUM(CASE WHEN "striker" = "p2" THEN "runs_scored" ELSE 0 END)                 AS "p2_runs"
    FROM    ball
    GROUP   BY "match_id","p1","p2"
),  /* find the maximum partnership total of each match */
max_pair AS (
    SELECT  "match_id",
            MAX("partnership_runs")  AS "max_runs"
    FROM    pair_runs
    GROUP   BY "match_id"
),  /* keep every pair that reaches the match maximum (ties allowed) */
top_pair AS (
    SELECT  pr."match_id",
            pr."p1", pr."p2",
            pr."p1_runs", pr."p2_runs",
            pr."partnership_runs"
    FROM    pair_runs AS pr
    JOIN    max_pair  AS mp
           ON pr."match_id" = mp."match_id"
          AND pr."partnership_runs" = mp."max_runs"
)
/* final formatting: order the two players within each pair as required */
SELECT  "match_id",
        CASE
            WHEN "p1_runs" > "p2_runs"
                 OR ("p1_runs" = "p2_runs" AND "p1" > "p2")
            THEN "p1" ELSE "p2" END                                   AS "player1_id",
        CASE
            WHEN "p1_runs" > "p2_runs"
                 OR ("p1_runs" = "p2_runs" AND "p1" > "p2")
            THEN "p1_runs" ELSE "p2_runs" END                         AS "player1_score",
        CASE
            WHEN "p1_runs" > "p2_runs"
                 OR ("p1_runs" = "p2_runs" AND "p1" > "p2")
            THEN "p2" ELSE "p1" END                                   AS "player2_id",
        CASE
            WHEN "p1_runs" > "p2_runs"
                 OR ("p1_runs" = "p2_runs" AND "p1" > "p2")
            THEN "p2_runs" ELSE "p1_runs" END                         AS "player2_score",
        "partnership_runs"
FROM    top_pair
ORDER BY "match_id", "player1_id", "player2_id";