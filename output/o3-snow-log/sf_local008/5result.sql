WITH agg AS (        -- aggregate career totals for every player
    SELECT
        PLAYER_ID,
        SUM(COALESCE(G,0))                                   AS total_games,
        SUM(COALESCE(TRY_TO_NUMBER(R),0))                    AS total_runs,
        SUM(COALESCE(TRY_TO_NUMBER(H),0))                    AS total_hits,
        SUM(COALESCE(TRY_TO_NUMBER(HR),0))                   AS total_hr
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY PLAYER_ID
),
max_vals AS (        -- highest totals for each statistic
    SELECT
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM agg
),
leaders AS (         -- players who hold (or share) the record for each stat
    SELECT PLAYER_ID, 'Games Played' AS metric, total_games AS score
    FROM agg, max_vals
    WHERE total_games = max_games

    UNION ALL
    SELECT PLAYER_ID, 'Runs'         AS metric, total_runs  AS score
    FROM agg, max_vals
    WHERE total_runs  = max_runs

    UNION ALL
    SELECT PLAYER_ID, 'Hits'         AS metric, total_hits  AS score
    FROM agg, max_vals
    WHERE total_hits  = max_hits

    UNION ALL
    SELECT PLAYER_ID, 'Home Runs'    AS metric, total_hr    AS score
    FROM agg, max_vals
    WHERE total_hr    = max_hr
)

SELECT
    l.metric,
    p.NAME_GIVEN,
    l.score
FROM leaders l
JOIN BASEBALL.BASEBALL.PLAYER p
      ON p.PLAYER_ID = l.PLAYER_ID
ORDER BY l.metric;