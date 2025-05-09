WITH  batsman_runs AS (               -- total runs scored by every batsman in every season
        SELECT  m."season_id",
                bb."striker"                           AS player_id,
                SUM(bs."runs_scored")                 AS total_runs
        FROM    IPL.IPL."BATSMAN_SCORED"  bs
        JOIN    IPL.IPL."BALL_BY_BALL"   bb
              ON bs."match_id"  = bb."match_id"
             AND bs."innings_no"= bb."innings_no"
             AND bs."over_id"   = bb."over_id"
             AND bs."ball_id"   = bb."ball_id"
        JOIN    IPL.IPL."MATCH"          m
              ON m."match_id"  = bs."match_id"
        GROUP BY m."season_id", bb."striker"
),  top_batsmen AS (                  -- rank batsmen; break ties with lower player_id
        SELECT  "season_id",
                player_id,
                total_runs,
                ROW_NUMBER() OVER (PARTITION BY "season_id"
                                   ORDER BY total_runs DESC, player_id ASC) AS pos
        FROM    batsman_runs
),  batsmen3 AS (                     -- keep only top-3
        SELECT  "season_id", pos,
                player_id  AS batsman_id,
                total_runs
        FROM    top_batsmen
        WHERE   pos <= 3
),  bowler_wkts AS (                  -- wickets for every bowler in every season
        SELECT  m."season_id",
                bb."bowler"                         AS player_id,
                COUNT(*)                           AS wickets
        FROM    IPL.IPL."WICKET_TAKEN" w
        JOIN    IPL.IPL."BALL_BY_BALL" bb
              ON w."match_id"   = bb."match_id"
             AND w."innings_no" = bb."innings_no"
             AND w."over_id"    = bb."over_id"
             AND w."ball_id"    = bb."ball_id"
        JOIN    IPL.IPL."MATCH"        m
              ON m."match_id" = w."match_id"
        WHERE   LOWER(w."kind_out") NOT IN ('run out','hit wicket','retired hurt')
        GROUP BY m."season_id", bb."bowler"
),  top_bowlers AS (                 -- rank bowlers; break ties with lower player_id
        SELECT  "season_id",
                player_id,
                wickets,
                ROW_NUMBER() OVER (PARTITION BY "season_id"
                                   ORDER BY wickets DESC, player_id ASC) AS pos
        FROM    bowler_wkts
),  bowlers3 AS (                    -- keep only top-3
        SELECT  "season_id", pos,
                player_id AS bowler_id,
                wickets
        FROM    top_bowlers
        WHERE   pos <= 3
),  combined AS (                    -- line up batsmen & bowlers by season and rank
        SELECT  COALESCE(b."season_id", bw."season_id") AS "season_id",
                COALESCE(b.pos,          bw.pos)        AS pos,
                b.batsman_id,
                b.total_runs,
                bw.bowler_id,
                bw.wickets
        FROM    batsmen3  b
        FULL JOIN bowlers3 bw
               ON b."season_id" = bw."season_id"
              AND b.pos         = bw.pos
),  final AS (                       -- pivot into one row per season (matched positions)
        SELECT  "season_id",

                MAX(CASE WHEN pos = 1 THEN batsman_id  END) AS batsman1_id,
                MAX(CASE WHEN pos = 1 THEN total_runs  END) AS batsman1_runs,
                MAX(CASE WHEN pos = 1 THEN bowler_id   END) AS bowler1_id,
                MAX(CASE WHEN pos = 1 THEN wickets     END) AS bowler1_wkts,

                MAX(CASE WHEN pos = 2 THEN batsman_id  END) AS batsman2_id,
                MAX(CASE WHEN pos = 2 THEN total_runs  END) AS batsman2_runs,
                MAX(CASE WHEN pos = 2 THEN bowler_id   END) AS bowler2_id,
                MAX(CASE WHEN pos = 2 THEN wickets     END) AS bowler2_wkts,

                MAX(CASE WHEN pos = 3 THEN batsman_id  END) AS batsman3_id,
                MAX(CASE WHEN pos = 3 THEN total_runs  END) AS batsman3_runs,
                MAX(CASE WHEN pos = 3 THEN bowler_id   END) AS bowler3_id,
                MAX(CASE WHEN pos = 3 THEN wickets     END) AS bowler3_wkts
        FROM    combined
        GROUP BY "season_id"
)
SELECT  "season_id",
        batsman1_id, batsman1_runs, bowler1_id, bowler1_wkts,
        batsman2_id, batsman2_runs, bowler2_id, bowler2_wkts,
        batsman3_id, batsman3_runs, bowler3_id, bowler3_wkts
FROM    final
ORDER BY "season_id" ASC;