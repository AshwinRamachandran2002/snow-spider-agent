-- Bowler with the lowest bowling average (runs conceded per wicket taken)
SELECT 
    p."player_name",
    ba."bowling_average"
FROM (
    -- compute bowling average for each bowler with at least one wicket
    SELECT
        t."bowler",
        CAST(t."total_runs_conceded" AS FLOAT) / w."wickets" AS "bowling_average"
    FROM (
        -- total runs conceded = runs off the bat + extras
        SELECT 
            r."bowler",
            (r."runs_off_bat" + COALESCE(e."extra_runs_conceded",0)) AS "total_runs_conceded"
        FROM (
            -- runs scored off the bat against each bowler
            SELECT 
                bb."bowler",
                SUM(bs."runs_scored") AS "runs_off_bat"
            FROM "ball_by_ball" AS bb
            JOIN "batsman_scored" AS bs
              ON bb."match_id" = bs."match_id"
             AND bb."over_id"  = bs."over_id"
             AND bb."ball_id"  = bs."ball_id"
            GROUP BY bb."bowler"
        ) AS r
        LEFT JOIN (
            -- extra runs conceded by each bowler
            SELECT 
                bb."bowler",
                SUM(er."extra_runs") AS "extra_runs_conceded"
            FROM "ball_by_ball" AS bb
            JOIN "extra_runs" AS er
              ON bb."match_id" = er."match_id"
             AND bb."over_id"  = er."over_id"
             AND bb."ball_id"  = er."ball_id"
            GROUP BY bb."bowler"
        ) AS e
          ON r."bowler" = e."bowler"
    ) AS t
    JOIN (
        -- wickets credited to each bowler (exclude run-outs)
        SELECT 
            bb."bowler",
            COUNT(*) AS "wickets"
        FROM "ball_by_ball" AS bb
        JOIN "wicket_taken" AS w
          ON bb."match_id" = w."match_id"
         AND bb."over_id"  = w."over_id"
         AND bb."ball_id"  = w."ball_id"
        WHERE w."kind_out" NOT LIKE 'run out'
        GROUP BY bb."bowler"
    ) AS w
      ON t."bowler" = w."bowler"
    WHERE w."wickets" > 0
) AS ba
JOIN "player" AS p
  ON p."player_id" = ba."bowler"
ORDER BY ba."bowling_average" ASC
LIMIT 1;