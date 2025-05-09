WITH pair_runs AS (
    -- one row per delivery with the two batters who are together
    SELECT
        b."match_id",
        CASE WHEN b."striker" < b."non_striker" THEN b."striker" ELSE b."non_striker" END AS player_a,
        CASE WHEN b."striker" < b."non_striker" THEN b."non_striker" ELSE b."striker" END AS player_b,
        b."striker"  AS striker_id,
        s."runs_scored"
    FROM "ball_by_ball"  AS b
    JOIN "batsman_scored" AS s
      ON b."match_id"   = s."match_id"
     AND b."innings_no" = s."innings_no"
     AND b."over_id"    = s."over_id"
     AND b."ball_id"    = s."ball_id"
),
agg_pair AS (
    -- total the runs made while the pair is together
    SELECT
        "match_id",
        player_a,
        player_b,
        SUM(CASE WHEN striker_id = player_a THEN runs_scored ELSE 0 END) AS runs_a,
        SUM(CASE WHEN striker_id = player_b THEN runs_scored ELSE 0 END) AS runs_b,
        SUM(runs_scored)                                                 AS partnership_runs
    FROM pair_runs
    GROUP BY "match_id", player_a, player_b
),
max_pair AS (
    -- maximum partnership runs within each match
    SELECT
        "match_id",
        MAX(partnership_runs) AS max_runs
    FROM agg_pair
    GROUP BY "match_id"
),
top_pair AS (
    -- keep every partnership that equals the maximum for that match (ties allowed)
    SELECT a.*
    FROM agg_pair AS a
    JOIN max_pair AS m
      ON a."match_id" = m."match_id"
     AND a.partnership_runs = m.max_runs
)
SELECT
    "match_id",
    -- decide player1 / player2 according to individual contribution and ID rules
    CASE
        WHEN runs_a > runs_b THEN player_a
        WHEN runs_a < runs_b THEN player_b
        ELSE CASE WHEN player_a > player_b THEN player_a ELSE player_b END
    END                                                            AS player1_id,
    CASE
        WHEN runs_a > runs_b THEN runs_a
        WHEN runs_a < runs_b THEN runs_b
        ELSE runs_a
    END                                                            AS player1_runs,
    CASE
        WHEN runs_a > runs_b THEN player_b
        WHEN runs_a < runs_b THEN player_a
        ELSE CASE WHEN player_a < player_b THEN player_a ELSE player_b END
    END                                                            AS player2_id,
    CASE
        WHEN runs_a > runs_b THEN runs_b
        WHEN runs_a < runs_b THEN runs_a
        ELSE runs_b
    END                                                            AS player2_runs,
    partnership_runs
FROM top_pair
ORDER BY "match_id",
         partnership_runs DESC,
         player1_id DESC,
         player2_id DESC;