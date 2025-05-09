WITH
/* 1.  most‑frequent role a player has had */
role_rank AS (
    SELECT  "player_id",
            "role",
            COUNT(*)                                        AS role_cnt,
            ROW_NUMBER() OVER (PARTITION BY "player_id"
                               ORDER BY COUNT(*) DESC,
                                        "role")            AS rn
    FROM    "player_match"
    GROUP   BY "player_id","role"
),
primary_role AS (
    SELECT "player_id", "role" AS primary_role
    FROM   role_rank
    WHERE  rn = 1
),

/* 2.  matches each player appeared in (any role) */
matches_played AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id") AS matches_played
    FROM    "player_match"
    GROUP   BY "player_id"
),

/* 3.  career batting totals */
runs_total AS (
    SELECT  "striker" AS player_id,
            SUM("runs_scored")           AS total_runs
    FROM    "batsman_scored"
    GROUP   BY "striker"
),
balls_faced AS (
    SELECT  "striker" AS player_id,
            COUNT(*)                      AS balls_faced
    FROM    "ball_by_ball"
    GROUP   BY "striker"
),
dismissals AS (
    SELECT  "player_out" AS player_id,
            COUNT(*)                      AS dismissals
    FROM    "wicket_taken"
    GROUP   BY "player_out"
),

/* 4.  per‑match runs to derive 30/50/100+ counts & HS */
per_match_runs AS (
    SELECT  "striker"      AS player_id,
            "match_id",
            SUM("runs_scored")  AS runs_in_match
    FROM    "batsman_scored"
    GROUP   BY "striker","match_id"
),
batting_buckets AS (
    SELECT  player_id,
            MAX(runs_in_match)                                           AS highest_score,
            SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)        AS match_30p,
            SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)        AS match_50p,
            SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)        AS match_100p
    FROM    per_match_runs
    GROUP   BY player_id
),

/* 5.  bowling stats  */
bowling_basic AS (
    SELECT  b."bowler"                        AS player_id,
            COUNT(*)                          AS balls_bowled,
            SUM(COALESCE(bs."runs_scored",0)) AS runs_conceded
    FROM    "ball_by_ball" b
    LEFT    JOIN "batsman_scored" bs
           USING ("match_id","over_id","ball_id")
    GROUP   BY b."bowler"
),
wickets_total AS (
    SELECT  b."bowler" AS player_id,
            COUNT(*)   AS total_wickets
    FROM    "ball_by_ball" b
    JOIN    "wicket_taken" w
           USING ("match_id","over_id","ball_id")
    GROUP   BY b."bowler"
),

/* 6.  best bowling in a single match (wkts‑runs) */
bowler_match_figs AS (
    SELECT  b."bowler" AS player_id,
            b."match_id",
            COUNT(w."player_out")                        AS wkts_in_match,
            SUM(COALESCE(bs."runs_scored",0))            AS runs_in_match
    FROM    "ball_by_ball" b
    LEFT    JOIN "wicket_taken"   w USING ("match_id","over_id","ball_id")
    LEFT    JOIN "batsman_scored" bs USING ("match_id","over_id","ball_id")
    GROUP   BY b."bowler", b."match_id"
),
best_wkts AS (
    SELECT  player_id,
            MAX(wkts_in_match) AS max_wkts
    FROM    bowler_match_figs
    GROUP   BY player_id
),
best_bowling AS (
    SELECT  f.player_id,
            printf('%d-%d', bw.max_wkts,
                   MIN(f.runs_in_match))     AS best_bowling
    FROM    bowler_match_figs f
    JOIN    best_wkts bw
      ON    f.player_id   = bw.player_id
     AND    f.wkts_in_match = bw.max_wkts
    GROUP   BY f.player_id
)

/* 7.  Final assembly */
SELECT  p."player_id",
        p."player_name",
        pr.primary_role,
        p."batting_hand",
        p."bowling_skill",

        COALESCE(rt.total_runs,0)                           AS total_runs,
        COALESCE(mp.matches_played,0)                       AS matches_played,
        COALESCE(d.dismissals,0)                            AS dismissals,
        CASE WHEN COALESCE(d.dismissals,0) > 0
             THEN ROUND(1.0*rt.total_runs/d.dismissals,4)
        END                                                 AS batting_avg,

        bb.highest_score,
        bb.match_30p,
        bb.match_50p,
        bb.match_100p,

        COALESCE(bf.balls_faced,0)                          AS balls_faced,
        CASE WHEN COALESCE(bf.balls_faced,0) > 0
             THEN ROUND(100.0*rt.total_runs/bf.balls_faced,4)
        END                                                 AS strike_rate,

        COALESCE(wt.total_wickets,0)                        AS total_wickets,
        CASE WHEN COALESCE(bbasic.balls_bowled,0) > 0
             THEN ROUND(
                     1.0*bbasic.runs_conceded /
                     (bbasic.balls_bowled/6.0),4)
        END                                                 AS economy_rate,

        bb2.best_bowling

FROM        "player"              p
LEFT  JOIN  primary_role          pr   ON p."player_id" = pr."player_id"
LEFT  JOIN  runs_total            rt   ON p."player_id" = rt."player_id"
LEFT  JOIN  matches_played        mp   ON p."player_id" = mp."player_id"
LEFT  JOIN  dismissals            d    ON p."player_id" = d."player_id"
LEFT  JOIN  batting_buckets       bb   ON p."player_id" = bb."player_id"
LEFT  JOIN  balls_faced           bf   ON p."player_id" = bf."player_id"
LEFT  JOIN  wickets_total         wt   ON p."player_id" = wt."player_id"
LEFT  JOIN  bowling_basic         bbasic ON p."player_id" = bbasic."player_id"
LEFT  JOIN  best_bowling          bb2  ON p."player_id" = bb2."player_id"
ORDER BY    p."player_id";