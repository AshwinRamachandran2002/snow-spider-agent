WITH delivery AS (      -- one row per ball delivered
    SELECT
        bb.bowler                            AS player_id,
        COALESCE(bs.runs_scored,0) +         -- runs off the bat
        COALESCE(                            -- extras that count against the bowler
            CASE
                WHEN er.extra_type IN ('legbyes','byes') THEN 0
                ELSE er.extra_runs
            END ,0)                          AS runs_conceded,
        CASE                                   -- was a wicket taken on this ball?
            WHEN wt.match_id IS NULL THEN 0
            ELSE 1
        END                                  AS is_wicket
    FROM "ball_by_ball"  bb
    LEFT JOIN "batsman_scored" bs
           ON bs.match_id  = bb.match_id
          AND bs.over_id   = bb.over_id
          AND bs.ball_id   = bb.ball_id
          AND bs.innings_no= bb.innings_no
    LEFT JOIN "extra_runs" er
           ON er.match_id  = bb.match_id
          AND er.over_id   = bb.over_id
          AND er.ball_id   = bb.ball_id
          AND er.innings_no= bb.innings_no
    LEFT JOIN "wicket_taken" wt
           ON wt.match_id  = bb.match_id
          AND wt.over_id   = bb.over_id
          AND wt.ball_id   = bb.ball_id
          AND wt.innings_no= bb.innings_no
),
bowler_stats AS (       -- aggregate to bowler level
    SELECT
        player_id,
        SUM(runs_conceded)        AS total_runs,
        SUM(is_wicket)            AS wickets
    FROM delivery
    GROUP BY player_id
    HAVING wickets > 0            -- ignore bowlers with no wickets
),
bowling_avg AS (        -- compute bowling average
    SELECT
        player_id,
        CAST(total_runs AS REAL) / wickets  AS avg_per_wicket
    FROM bowler_stats
)
SELECT p.player_name
FROM   bowling_avg   ba
JOIN   player        p  ON p.player_id = ba.player_id
ORDER BY ba.avg_per_wicket ASC, p.player_name
LIMIT 1;