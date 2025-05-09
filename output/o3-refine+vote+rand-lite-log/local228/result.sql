WITH batsman_runs AS (
    /* total runs per batsman in every season */
    SELECT
        m.season_id,
        bb.striker               AS player_id,
        SUM(bs.runs_scored)      AS total_runs
    FROM batsman_scored   bs
    JOIN ball_by_ball     bb  ON bs.match_id  = bb.match_id
                             AND bs.over_id   = bb.over_id
                             AND bs.ball_id   = bb.ball_id
                             AND bs.innings_no= bb.innings_no
    JOIN match            m   ON m.match_id   = bs.match_id
    GROUP BY m.season_id, bb.striker
),
batsman_rank AS (
    /* rank batsmen: more runs first, lower player_id breaks ties */
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_runs DESC, player_id ASC
        ) AS rn
    FROM batsman_runs
),
top_batsmen AS (
    SELECT season_id, player_id, total_runs, rn
    FROM   batsman_rank
    WHERE  rn <= 3
),
bowler_wkts AS (
    /* wickets credited to bowlers (exclude specified kinds) */
    SELECT
        m.season_id,
        bb.bowler             AS player_id,
        COUNT(*)              AS total_wkts
    FROM wicket_taken   wt
    JOIN ball_by_ball   bb  ON wt.match_id   = bb.match_id
                           AND wt.over_id    = bb.over_id
                           AND wt.ball_id    = bb.ball_id
                           AND wt.innings_no = bb.innings_no
    JOIN match          m   ON m.match_id    = wt.match_id
    WHERE LOWER(wt.kind_out) NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m.season_id, bb.bowler
),
bowler_rank AS (
    /* rank bowlers: more wickets first, lower player_id breaks ties */
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (
            PARTITION BY season_id
            ORDER BY total_wkts DESC, player_id ASC
        ) AS rn
    FROM bowler_wkts
),
top_bowlers AS (
    SELECT season_id, player_id, total_wkts, rn
    FROM   bowler_rank
    WHERE  rn <= 3
)
SELECT
    b.season_id,
    b.player_id  AS batsman_id,
    b.total_runs,
    bo.player_id AS bowler_id,
    bo.total_wkts
FROM top_batsmen b
JOIN top_bowlers bo
  ON  b.season_id = bo.season_id
  AND b.rn        = bo.rn          -- match 1st with 1st, 2nd with 2nd, 3rd with 3rd
ORDER BY
    b.season_id,
    b.rn;