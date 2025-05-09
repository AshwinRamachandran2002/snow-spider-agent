WITH player_base AS (
    SELECT
        "player_id",
        "player_name",
        "batting_hand",
        "bowling_skill"
    FROM IPL.IPL.PLAYER
),

/*------------ most-frequent role ------------*/
role_counts AS (
    SELECT
        "player_id",
        "role",
        COUNT(*) AS role_cnt
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id", "role"
),
role_most AS (
    SELECT
        "player_id",
        "role"
    FROM (
        SELECT
            "player_id",
            "role",
            role_cnt,
            RANK() OVER (PARTITION BY "player_id"
                         ORDER BY role_cnt DESC, "role") AS rnk
        FROM role_counts
    )
    WHERE rnk = 1
),

/*------------ matches played ------------*/
matches_played AS (
    SELECT
        "player_id",
        COUNT(DISTINCT "match_id") AS matches_played
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),

/*------------ batting ‑ runs & balls faced ------------*/
balls_faced AS (
    SELECT
        BB."striker"   AS player_id,
        BB."match_id",
        BS."runs_scored"
    FROM IPL.IPL.BATSMAN_SCORED  BS
    JOIN IPL.IPL.BALL_BY_BALL    BB
      ON BB."match_id"   = BS."match_id"
     AND BB."over_id"    = BS."over_id"
     AND BB."ball_id"    = BS."ball_id"
     AND BB."innings_no" = BS."innings_no"
),
batting_agg AS (
    SELECT
        player_id,
        SUM("runs_scored") AS total_runs,
        COUNT(*)           AS balls_faced
    FROM balls_faced
    GROUP BY player_id
),

/*------------ dismissals ------------*/
dismissals AS (
    SELECT
        "player_out" AS player_id,
        COUNT(*)     AS dismissals
    FROM IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),

/*------------ per-match run aggregates ------------*/
match_runs AS (
    SELECT
        player_id,
        "match_id",
        SUM("runs_scored") AS match_runs
    FROM balls_faced
    GROUP BY player_id, "match_id"
),
high_score AS (
    SELECT
        player_id,
        MAX(match_runs) AS high_score
    FROM match_runs
    GROUP BY player_id
),
run_milestones AS (
    SELECT
        player_id,
        SUM(CASE WHEN match_runs >=  30 THEN 1 ELSE 0 END) AS matches_30_plus,
        SUM(CASE WHEN match_runs >=  50 THEN 1 ELSE 0 END) AS matches_50_plus,
        SUM(CASE WHEN match_runs >= 100 THEN 1 ELSE 0 END) AS matches_100_plus
    FROM match_runs
    GROUP BY player_id
),

/*------------ bowling: runs conceded & balls bowled ------------*/
bowling_runs AS (
    SELECT
        BB."bowler"  AS player_id,
        BB."match_id",
        SUM(BS."runs_scored") AS runs_conceded,
        COUNT(*)              AS balls_bowled
    FROM IPL.IPL.BATSMAN_SCORED BS
    JOIN IPL.IPL.BALL_BY_BALL  BB
      ON BB."match_id"   = BS."match_id"
     AND BB."over_id"    = BS."over_id"
     AND BB."ball_id"    = BS."ball_id"
     AND BB."innings_no" = BS."innings_no"
    GROUP BY BB."bowler", BB."match_id"
),
bowling_agg AS (
    SELECT
        player_id,
        SUM(runs_conceded) AS total_runs_conceded,
        SUM(balls_bowled)  AS total_balls_bowled
    FROM bowling_runs
    GROUP BY player_id
),

/*------------ wickets ------------*/
wickets_per_match AS (
    SELECT
        BB."bowler" AS player_id,
        BB."match_id",
        COUNT(*)    AS wickets_taken
    FROM IPL.IPL.WICKET_TAKEN W
    JOIN IPL.IPL.BALL_BY_BALL BB
      ON BB."match_id"   = W."match_id"
     AND BB."over_id"    = W."over_id"
     AND BB."ball_id"    = W."ball_id"
     AND BB."innings_no" = W."innings_no"
    GROUP BY BB."bowler", BB."match_id"
),
wickets_agg AS (
    SELECT
        player_id,
        SUM(wickets_taken) AS total_wickets
    FROM wickets_per_match
    GROUP BY player_id
),

/*------------ best bowling in a match ------------*/
best_bowling_raw AS (
    SELECT
        w.player_id,
        w."match_id",
        w.wickets_taken,
        COALESCE(br.runs_conceded, 0) AS runs_conceded
    FROM wickets_per_match w
    LEFT JOIN bowling_runs br
           ON br.player_id = w.player_id
          AND br."match_id" = w."match_id"
),
best_bowling_pick AS (
    SELECT
        player_id,
        FIRST_VALUE(TO_VARCHAR(wickets_taken) || '-' || TO_VARCHAR(runs_conceded))
            OVER (PARTITION BY player_id
                  ORDER BY wickets_taken DESC,
                           runs_conceded ASC,
                           "match_id") AS best_bowling
    FROM best_bowling_raw
    QUALIFY ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY wickets_taken DESC,
                                        runs_conceded ASC,
                                        "match_id") = 1
),

/*------------ economy rate ------------*/
economy AS (
    SELECT
        player_id,
        CASE
            WHEN total_balls_bowled > 0
            THEN ROUND((total_runs_conceded * 6.0) / total_balls_bowled, 4)
        END AS economy_rate
    FROM bowling_agg
)

/*==================== final output ====================*/
SELECT
    pb."player_id",
    pb."player_name",
    rm."role"                               AS most_frequent_role,
    pb."batting_hand",
    pb."bowling_skill",
    COALESCE(bat.total_runs, 0)             AS total_runs_scored,
    COALESCE(mp.matches_played, 0)          AS total_matches_played,
    COALESCE(dis.dismissals, 0)             AS total_dismissals,
    CASE WHEN COALESCE(dis.dismissals, 0) > 0
         THEN ROUND(bat.total_runs / dis.dismissals, 4) END
                                             AS batting_average,
    COALESCE(hs.high_score, 0)              AS highest_score,
    COALESCE(rmiles.matches_30_plus, 0)     AS matches_with_30_plus,
    COALESCE(rmiles.matches_50_plus, 0)     AS matches_with_50_plus,
    COALESCE(rmiles.matches_100_plus, 0)    AS matches_with_100_plus,
    COALESCE(bat.balls_faced, 0)            AS total_balls_faced,
    CASE WHEN COALESCE(bat.balls_faced, 0) > 0
         THEN ROUND((bat.total_runs * 100.0) / bat.balls_faced, 4) END
                                             AS strike_rate,
    COALESCE(wi.total_wickets, 0)           AS total_wickets_taken,
    eco.economy_rate                        AS economy_rate,
    bb.best_bowling                         AS best_bowling_performance
FROM player_base           pb
LEFT JOIN role_most        rm     ON rm."player_id"   = pb."player_id"
LEFT JOIN matches_played   mp     ON mp."player_id"   = pb."player_id"
LEFT JOIN batting_agg      bat    ON bat.player_id    = pb."player_id"
LEFT JOIN dismissals       dis    ON dis.player_id    = pb."player_id"
LEFT JOIN high_score       hs     ON hs.player_id     = pb."player_id"
LEFT JOIN run_milestones   rmiles ON rmiles.player_id = pb."player_id"
LEFT JOIN wickets_agg      wi     ON wi.player_id     = pb."player_id"
LEFT JOIN economy          eco    ON eco.player_id    = pb."player_id"
LEFT JOIN best_bowling_pick bb    ON bb.player_id     = pb."player_id"
ORDER BY pb."player_id";