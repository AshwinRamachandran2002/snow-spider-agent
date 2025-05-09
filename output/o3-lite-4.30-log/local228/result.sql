WITH top_batsmen AS (
    SELECT *
    FROM (
        SELECT
            m.season_id,
            bbb.striker                                   AS player_id,
            SUM(bs.runs_scored)                           AS total_runs,
            ROW_NUMBER() OVER (
                PARTITION BY m.season_id
                ORDER BY SUM(bs.runs_scored) DESC, bbb.striker
            )                                             AS pos
        FROM match            AS m
        JOIN ball_by_ball     AS bbb ON bbb.match_id = m.match_id
        JOIN batsman_scored   AS bs  ON bs.match_id   = bbb.match_id
                                     AND bs.over_id  = bbb.over_id
                                     AND bs.ball_id  = bbb.ball_id
                                     AND bs.innings_no = bbb.innings_no
        GROUP BY m.season_id, bbb.striker
    )
    WHERE pos <= 3
),
top_bowlers AS (
    SELECT *
    FROM (
        SELECT
            m.season_id,
            bbb.bowler                                    AS player_id,
            COUNT(*)                                      AS wickets,
            ROW_NUMBER() OVER (
                PARTITION BY m.season_id
                ORDER BY COUNT(*) DESC, bbb.bowler
            )                                             AS pos
        FROM match          AS m
        JOIN ball_by_ball   AS bbb ON bbb.match_id = m.match_id
        JOIN wicket_taken   AS wt  ON wt.match_id   = bbb.match_id
                                   AND wt.over_id   = bbb.over_id
                                   AND wt.ball_id   = bbb.ball_id
                                   AND wt.innings_no= bbb.innings_no
        WHERE wt.kind_out NOT IN ('run out','hit wicket','retired hurt')
        GROUP BY m.season_id, bbb.bowler
    )
    WHERE pos <= 3
),
paired AS (
    SELECT
        b.season_id,
        b.pos,
        b.player_id AS batsman_id,
        b.total_runs,
        w.player_id AS bowler_id,
        w.wickets
    FROM top_batsmen b
    JOIN top_bowlers w
      ON w.season_id = b.season_id
     AND w.pos       = b.pos
)
SELECT
    season_id,
    MAX(CASE WHEN pos = 1 THEN batsman_id  END) AS batsman1_id,
    MAX(CASE WHEN pos = 1 THEN total_runs  END) AS batsman1_total_runs,
    MAX(CASE WHEN pos = 1 THEN bowler_id   END) AS bowler1_id,
    MAX(CASE WHEN pos = 1 THEN wickets     END) AS bowler1_total_wickets,
    MAX(CASE WHEN pos = 2 THEN batsman_id  END) AS batsman2_id,
    MAX(CASE WHEN pos = 2 THEN total_runs  END) AS batsman2_total_runs,
    MAX(CASE WHEN pos = 2 THEN bowler_id   END) AS bowler2_id,
    MAX(CASE WHEN pos = 2 THEN wickets     END) AS bowler2_total_wickets,
    MAX(CASE WHEN pos = 3 THEN batsman_id  END) AS batsman3_id,
    MAX(CASE WHEN pos = 3 THEN total_runs  END) AS batsman3_total_runs,
    MAX(CASE WHEN pos = 3 THEN bowler_id   END) AS bowler3_id,
    MAX(CASE WHEN pos = 3 THEN wickets     END) AS bowler3_total_wickets
FROM paired
GROUP BY season_id
ORDER BY season_id;