WITH
/*-----------  total runs by every batsman for every season  -----------*/
BATTING AS (
    SELECT
        m."season_id"                              AS SEASON_ID,
        bb."striker"                               AS PLAYER_ID,
        SUM(bs."runs_scored")                      AS TOTAL_RUNS
    FROM IPL.IPL.BATSMAN_SCORED  bs
    JOIN IPL.IPL.BALL_BY_BALL    bb
      ON  bs."match_id"   = bb."match_id"
      AND bs."over_id"    = bb."over_id"
      AND bs."ball_id"    = bb."ball_id"
      AND bs."innings_no" = bb."innings_no"
    JOIN IPL.IPL.MATCH           m
      ON  bs."match_id" = m."match_id"
    GROUP BY
        m."season_id",
        bb."striker"
),

/*-----------  pick top-3 batsmen per season  -----------*/
BATSMAN_TOP3 AS (
    SELECT
        SEASON_ID,
        PLAYER_ID,
        TOTAL_RUNS,
        ROW_NUMBER() OVER (PARTITION BY SEASON_ID
                           ORDER BY TOTAL_RUNS DESC, PLAYER_ID ASC) AS RN
    FROM BATTING
    QUALIFY RN <= 3
),

/*-----------  total wickets by every bowler for every season  -----------*/
BOWLING AS (
    SELECT
        m."season_id"                              AS SEASON_ID,
        bb."bowler"                                AS PLAYER_ID,
        COUNT(*)                                   AS TOTAL_WKTS
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL bb
      ON  wt."match_id"   = bb."match_id"
      AND wt."over_id"    = bb."over_id"
      AND wt."ball_id"    = bb."ball_id"
      AND wt."innings_no" = bb."innings_no"
    JOIN IPL.IPL.MATCH        m
      ON  wt."match_id" = m."match_id"
    WHERE LOWER(wt."kind_out") NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY
        m."season_id",
        bb."bowler"
),

/*-----------  pick top-3 bowlers per season  -----------*/
BOWLER_TOP3 AS (
    SELECT
        SEASON_ID,
        PLAYER_ID,
        TOTAL_WKTS,
        ROW_NUMBER() OVER (PARTITION BY SEASON_ID
                           ORDER BY TOTAL_WKTS DESC, PLAYER_ID ASC) AS RN
    FROM BOWLING
    QUALIFY RN <= 3
)

/*-----------  match positions: 1⇔1 , 2⇔2 , 3⇔3  -----------*/
SELECT
    b.SEASON_ID,
    b.PLAYER_ID   AS BATSMAN_ID,
    b.TOTAL_RUNS,
    w.PLAYER_ID   AS BOWLER_ID,
    w.TOTAL_WKTS
FROM BATSMAN_TOP3 b
JOIN BOWLER_TOP3 w
  ON  b.SEASON_ID = w.SEASON_ID
  AND b.RN        = w.RN
ORDER BY
    b.SEASON_ID ASC,
    b.RN        ASC;