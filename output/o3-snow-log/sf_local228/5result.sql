WITH
/*-----------------------------*
 | 1. Total runs per batsman   |
 *-----------------------------*/
BATSMAN_RUNS AS (
    SELECT
        m."season_id"                AS season_id,
        bb."striker"                 AS player_id,
        SUM(bs."runs_scored")        AS total_runs
    FROM "IPL"."IPL"."BATSMAN_SCORED"  bs
    JOIN "IPL"."IPL"."BALL_BY_BALL"    bb
      ON  bs."match_id"   = bb."match_id"
     AND  bs."over_id"    = bb."over_id"
     AND  bs."ball_id"    = bb."ball_id"
     AND  bs."innings_no" = bb."innings_no"
    JOIN "IPL"."IPL"."MATCH"           m
      ON bs."match_id" = m."match_id"
    GROUP BY m."season_id", bb."striker"
),

/*----------------------------------------------*
 | 2. Top-3 batsmen per season (tie-break rules) |
 *----------------------------------------------*/
BATSMAN_TOP3 AS (
    SELECT
        season_id,
        player_id           AS batsman_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS pos
    FROM BATSMAN_RUNS
    QUALIFY pos <= 3
),

/*-----------------------------*
 | 3. Total wickets per bowler |
 *-----------------------------*/
BOWLER_WKTS AS (
    SELECT
        m."season_id"                AS season_id,
        bb."bowler"                  AS player_id,
        COUNT(*)                     AS total_wkts
    FROM "IPL"."IPL"."WICKET_TAKEN"   wt
    JOIN "IPL"."IPL"."BALL_BY_BALL"   bb
      ON  wt."match_id"   = bb."match_id"
     AND  wt."over_id"    = bb."over_id"
     AND  wt."ball_id"    = bb."ball_id"
     AND  wt."innings_no" = bb."innings_no"
    JOIN "IPL"."IPL"."MATCH"          m
      ON wt."match_id" = m."match_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),

/*---------------------------------------------*
 | 4. Top-3 bowlers per season (tie-break rule) |
 *---------------------------------------------*/
BOWLER_TOP3 AS (
    SELECT
        season_id,
        player_id         AS bowler_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS pos
    FROM BOWLER_WKTS
    QUALIFY pos <= 3
)

/*--------------------------------------------------------------*
 | 5. Match top batsmen & bowlers position-wise and final output |
 *--------------------------------------------------------------*/
SELECT
    b.season_id                       AS season_id,
    b.pos                             AS position,
    b.batsman_id                      AS batsman_player_id,
    b.total_runs                      AS total_runs,
    w.bowler_id                       AS bowler_player_id,
    w.total_wkts                      AS total_wickets
FROM BATSMAN_TOP3 b
JOIN BOWLER_TOP3  w
  ON b.season_id = w.season_id
 AND b.pos       = w.pos
ORDER BY
    season_id ASC,
    position   ASC;