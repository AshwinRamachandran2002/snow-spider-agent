WITH wickets_per_bowler AS (
    SELECT bb."bowler", COUNT(*) AS total_wickets
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON wt."match_id" = bb."match_id"
     AND wt."over_id" = bb."over_id"
     AND wt."ball_id" = bb."ball_id"
    GROUP BY bb."bowler"
),
runs_per_bowler AS (
    SELECT bb."bowler", SUM(bs."runs_scored") AS total_runs_conceded
    FROM IPL.IPL.BALL_BY_BALL bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON bb."match_id" = bs."match_id"
     AND bb."over_id" = bs."over_id"
     AND bb."ball_id" = bs."ball_id"
    GROUP BY bb."bowler"
),
balls_per_bowler AS (
    SELECT bb."bowler", COUNT(*) AS balls_bowled
    FROM IPL.IPL.BALL_BY_BALL bb
    LEFT JOIN IPL.IPL.EXTRA_RUNS er 
      ON bb."match_id" = er."match_id"
     AND bb."over_id" = er."over_id"
     AND bb."ball_id" = er."ball_id"
    WHERE er."extra_type" IS NULL OR er."extra_type" NOT IN ('wides', 'noballs')
    GROUP BY bb."bowler"
),
best_performance AS (
    SELECT bb."bowler", wt."match_id", COUNT(*) AS wickets_in_match, SUM(bs."runs_scored") AS runs_conceded
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON wt."match_id" = bb."match_id"
     AND wt."over_id" = bb."over_id"
     AND wt."ball_id" = bb."ball_id"
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON bb."match_id" = bs."match_id"
     AND bb."over_id" = bs."over_id"
     AND bb."ball_id" = bs."ball_id"
    GROUP BY bb."bowler", wt."match_id"
),
best_performance_per_bowler AS (
    SELECT bp1."bowler", CONCAT(bp1.wickets_in_match, '-', bp1.runs_conceded) AS best_performance
    FROM best_performance bp1
    JOIN (
        SELECT "bowler", MAX(wickets_in_match) AS max_wickets
        FROM best_performance
        GROUP BY "bowler"
    ) bp2
      ON bp1."bowler" = bp2."bowler"
     AND bp1.wickets_in_match = bp2.max_wickets
    QUALIFY ROW_NUMBER() OVER (PARTITION BY bp1."bowler" ORDER BY bp1.runs_conceded ASC) = 1
),
bowler_info AS (
    SELECT p."player_name", bd."bowler", bd.balls_bowled,
           wd.total_wickets, rd.total_runs_conceded
    FROM balls_per_bowler bd
    JOIN wickets_per_bowler wd ON bd."bowler" = wd."bowler"
    JOIN runs_per_bowler rd ON bd."bowler" = rd."bowler"
    JOIN IPL.IPL.PLAYER p ON bd."bowler" = p."player_id"
)
SELECT bi."player_name" AS bowler_name,
       bi.total_wickets,
       ROUND(bi.total_runs_conceded / (bi.balls_bowled / 6.0), 4) AS economy_rate,
       ROUND(bi.balls_bowled / bi.total_wickets, 4) AS strike_rate,
       bp.best_performance
FROM bowler_info bi
LEFT JOIN best_performance_per_bowler bp ON bi."bowler" = bp."bowler"
ORDER BY bi."player_name";