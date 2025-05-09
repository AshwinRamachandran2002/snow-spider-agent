WITH
/*--------------------------------------------------*
 | Basic player information                         |
 *--------------------------------------------------*/
player_info AS (
    SELECT  p."player_id",
            p."player_name",
            p."batting_hand",
            p."bowling_skill"
    FROM    IPL.IPL.PLAYER p
),

/*--------------------------------------------------*
 | Most–frequent role per player                    |
 *--------------------------------------------------*/
role_counts AS (
    SELECT  pm."player_id",
            pm."role",
            COUNT(*)                                                     AS cnt,
            ROW_NUMBER() OVER (PARTITION BY pm."player_id"
                               ORDER BY COUNT(*) DESC, pm."role")        AS rn
    FROM    IPL.IPL.PLAYER_MATCH pm
    GROUP BY pm."player_id", pm."role"
),
most_role AS (
    SELECT  "player_id",
            "role"   AS most_frequent_role
    FROM    role_counts
    WHERE   rn = 1
),

/*--------------------------------------------------*
 | Matches played                                   |
 *--------------------------------------------------*/
player_matches AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id") AS matches_played
    FROM    IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),

/*--------------------------------------------------*
 | Batting: runs & balls per match                  |
 *--------------------------------------------------*/
player_runs_match AS (
    SELECT  b."striker"                 AS player_id,
            b."match_id",
            SUM(bs."runs_scored")       AS runs_scored,
            COUNT(*)                    AS balls_faced
    FROM    IPL.IPL.BALL_BY_BALL  b
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    GROUP BY b."striker", b."match_id"
),

/*--------------------------------------------------*
 | Batting aggregates                               |
 *--------------------------------------------------*/
batting_agg AS (
    SELECT  player_id,
            SUM(runs_scored)                                AS total_runs,
            SUM(balls_faced)                                AS balls_faced,
            MAX(runs_scored)                                AS highest_score,
            SUM(CASE WHEN runs_scored >=  30 THEN 1 ELSE 0 END) AS matches_30,
            SUM(CASE WHEN runs_scored >=  50 THEN 1 ELSE 0 END) AS matches_50,
            SUM(CASE WHEN runs_scored >= 100 THEN 1 ELSE 0 END) AS matches_100
    FROM    player_runs_match
    GROUP BY player_id
),

/*--------------------------------------------------*
 | Dismissals                                       |
 *--------------------------------------------------*/
player_dismissals AS (
    SELECT  "player_out" AS player_id,
            COUNT(*)     AS dismissals
    FROM    IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),

/*--------------------------------------------------*
 | Bowling: runs conceded & balls bowled per match  |
 *--------------------------------------------------*/
bowler_runs_match AS (
    SELECT  b."bowler"                AS player_id,
            b."match_id",
            SUM(bs."runs_scored")     AS runs_conceded,
            COUNT(*)                  AS balls_bowled
    FROM    IPL.IPL.BALL_BY_BALL b
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    GROUP BY b."bowler", b."match_id"
),
bowler_runs_agg AS (
    SELECT  player_id,
            SUM(runs_conceded)    AS total_runs_conceded,
            SUM(balls_bowled)     AS balls_bowled
    FROM    bowler_runs_match
    GROUP BY player_id
),

/*--------------------------------------------------*
 | Bowling: wickets per match & total wickets       |
 *--------------------------------------------------*/
bowler_wickets_match AS (
    SELECT  b."bowler" AS player_id,
            b."match_id",
            COUNT(*)    AS wickets
    FROM    IPL.IPL.WICKET_TAKEN w
    JOIN    IPL.IPL.BALL_BY_BALL b
           ON  w."match_id"   = b."match_id"
           AND w."innings_no" = b."innings_no"
           AND w."over_id"    = b."over_id"
           AND w."ball_id"    = b."ball_id"
    GROUP BY b."bowler", b."match_id"
),
bowler_wickets_agg AS (
    SELECT  player_id,
            SUM(wickets) AS wickets_taken
    FROM    bowler_wickets_match
    GROUP BY player_id
),

/*--------------------------------------------------*
 | Best bowling figures per player                  |
 *--------------------------------------------------*/
bowler_performance_match AS (
    SELECT  rm.player_id,
            COALESCE(wm.wickets, 0) AS wickets,
            rm.runs_conceded
    FROM    bowler_runs_match   rm
    LEFT JOIN bowler_wickets_match wm
           ON  rm.player_id = wm.player_id
          AND rm."match_id" = wm."match_id"
),
best_bowling AS (
    SELECT  player_id,
            CONCAT(wickets, '-', runs_conceded) AS best_bowling
    FROM   (
        SELECT  player_id,
                wickets,
                runs_conceded,
                ROW_NUMBER() OVER (PARTITION BY player_id
                                   ORDER BY wickets DESC, runs_conceded ASC) AS rn
        FROM    bowler_performance_match
    )
    WHERE   rn = 1
)

/*--------------------------------------------------*
 | Final select                                     |
 *--------------------------------------------------*/
SELECT
        pi."player_id",
        pi."player_name",
        mr.most_frequent_role,
        pi."batting_hand",
        pi."bowling_skill",

        /* Batting */
        COALESCE(ba.total_runs,   0)                                                AS total_runs,
        COALESCE(pm.matches_played, 0)                                              AS matches_played,
        COALESCE(pd.dismissals,   0)                                                AS dismissals,
        CASE WHEN COALESCE(pd.dismissals,0) = 0
             THEN NULL
             ELSE ROUND(ba.total_runs / pd.dismissals, 4)
        END                                                                         AS batting_average,
        COALESCE(ba.highest_score, 0)                                               AS highest_score,
        COALESCE(ba.matches_30,    0)                                               AS matches_30,
        COALESCE(ba.matches_50,    0)                                               AS matches_50,
        COALESCE(ba.matches_100,   0)                                               AS matches_100,
        COALESCE(ba.balls_faced,   0)                                               AS balls_faced,
        CASE WHEN COALESCE(ba.balls_faced,0) = 0
             THEN NULL
             ELSE ROUND( (ba.total_runs / ba.balls_faced) * 100, 4)
        END                                                                         AS strike_rate,

        /* Bowling */
        COALESCE(bw.wickets_taken,      0)                                          AS wickets_taken,
        CASE WHEN COALESCE(br.balls_bowled,0) = 0
             THEN NULL
             ELSE ROUND( (br.total_runs_conceded / br.balls_bowled) * 6, 4)
        END                                                                         AS economy_rate,
        bb.best_bowling

FROM        player_info          pi
LEFT JOIN   most_role            mr  ON pi."player_id" = mr."player_id"
LEFT JOIN   player_matches       pm  ON pi."player_id" = pm."player_id"
LEFT JOIN   batting_agg          ba  ON pi."player_id" = ba.player_id
LEFT JOIN   player_dismissals    pd  ON pi."player_id" = pd.player_id
LEFT JOIN   bowler_runs_agg      br  ON pi."player_id" = br.player_id
LEFT JOIN   bowler_wickets_agg   bw  ON pi."player_id" = bw.player_id
LEFT JOIN   best_bowling         bb  ON pi."player_id" = bb.player_id
ORDER BY    pi."player_id";