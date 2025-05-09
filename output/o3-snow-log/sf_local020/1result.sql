WITH wickets_per_bowler AS (          -- wickets credited to each bowler
    SELECT  b."bowler"         AS bowler_id,
            COUNT(*)            AS wickets
    FROM    "IPL"."IPL"."WICKET_TAKEN" w
    JOIN    "IPL"."IPL"."BALL_BY_BALL" b
           USING ("match_id","innings_no","over_id","ball_id")
    WHERE   LOWER(w."kind_out") <> 'run out'                         -- exclude run-outs
    GROUP BY b."bowler"
),
runs_per_bowler AS (             -- runs conceded by each bowler
    SELECT  b."bowler"                                               AS bowler_id,
            SUM( COALESCE(bs."runs_scored",0) ) +                    -- off the bat
            SUM( CASE                                                -- eligible extras
                     WHEN er."extra_type" IS NULL                      THEN 0
                     WHEN LOWER(er."extra_type") IN ('legbyes','byes') THEN 0
                     ELSE COALESCE(er."extra_runs",0)
                 END )                                              AS runs_conceded
    FROM    "IPL"."IPL"."BALL_BY_BALL"    b
    LEFT JOIN "IPL"."IPL"."BATSMAN_SCORED" bs
           USING ("match_id","innings_no","over_id","ball_id")
    LEFT JOIN "IPL"."IPL"."EXTRA_RUNS"     er
           USING ("match_id","innings_no","over_id","ball_id")
    GROUP BY b."bowler"
),
bowling_average AS (              -- combine runs and wickets
    SELECT  r.bowler_id,
            r.runs_conceded,
            w.wickets,
            r.runs_conceded / w.wickets     AS bowling_avg
    FROM    runs_per_bowler   r
    JOIN    wickets_per_bowler w ON r.bowler_id = w.bowler_id
    WHERE   w.wickets > 0                          -- keep only bowlers with a wicket
)
SELECT      p."player_name"        AS bowler_name,
            ROUND(b.bowling_avg,4) AS bowling_average
FROM        bowling_average b
JOIN        "IPL"."IPL"."PLAYER" p
           ON p."player_id" = b.bowler_id
ORDER BY    b.bowling_avg ASC, p."player_name" ASC
LIMIT 1;