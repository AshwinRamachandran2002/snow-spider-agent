WITH
/*--------------- 1.  Total runs scored by every batsman in each season ----------------*/
batsman_season_runs AS (
    SELECT
        m."season_id"      AS season_id,
        bb."striker"       AS player_id,
        SUM(bs."runs_scored") AS total_runs
    FROM IPL.IPL.BATSMAN_SCORED  bs
    JOIN IPL.IPL.BALL_BY_BALL    bb
         ON  bs."match_id"   = bb."match_id"
         AND bs."innings_no" = bb."innings_no"
         AND bs."over_id"    = bb."over_id"
         AND bs."ball_id"    = bb."ball_id"
    JOIN IPL.IPL.MATCH          m
         ON  m."match_id" = bs."match_id"
    GROUP BY m."season_id", bb."striker"
),

/*--------------- 2.  Three highest-run scorers per season ----------------*/
batsmen_ranked AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_runs DESC, player_id ASC
        ) AS rank_pos
    FROM batsman_season_runs
    QUALIFY rank_pos <= 3
),

/*--------------- 3.  Total wickets for every bowler in each season ----------------*/
bowler_season_wkts AS (
    SELECT
        m."season_id"      AS season_id,
        bb."bowler"        AS player_id,
        COUNT(*)           AS total_wkts
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
         ON  wt."match_id"   = bb."match_id"
         AND wt."innings_no" = bb."innings_no"
         AND wt."over_id"    = bb."over_id"
         AND wt."ball_id"    = bb."ball_id"
    JOIN IPL.IPL.MATCH        m
         ON  m."match_id" = wt."match_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m."season_id", bb."bowler"
),

/*--------------- 4.  Three highest wicket-takers per season ----------------*/
bowlers_ranked AS (
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_wkts DESC, player_id ASC
        ) AS rank_pos
    FROM bowler_season_wkts
    QUALIFY rank_pos <= 3
),

/*--------------- 5.  Pair batsmen and bowlers by rank within each season -------------*/
paired AS (
    SELECT
        b_season.season_id,
        b_season.rank_pos            AS rank,
        bp."player_name"             AS batsman_name,
        b_season.total_runs,
        blp."player_name"            AS bowler_name,
        bl_season.total_wkts
    FROM batsmen_ranked  b_season
    JOIN bowlers_ranked  bl_season
          ON  b_season.season_id = bl_season.season_id
          AND b_season.rank_pos  = bl_season.rank_pos
    JOIN IPL.IPL.PLAYER  bp
          ON bp."player_id" = b_season.player_id
    JOIN IPL.IPL.PLAYER  blp
          ON blp."player_id" = bl_season.player_id
)

/*--------------- 6.  Final output ----------------------------------------*/
SELECT
    season_id,
    rank,
    batsman_name,
    total_runs,
    bowler_name,
    total_wkts
FROM paired
ORDER BY season_id ASC, rank ASC;