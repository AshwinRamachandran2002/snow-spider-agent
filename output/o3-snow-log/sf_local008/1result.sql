WITH career_totals AS (
    SELECT
        player_id,

        /* total games (numeric column) */
        SUM(COALESCE(g, 0))                                                AS total_games,

        /* text columns → pull out digits, convert to number, default to 0 */
        SUM(COALESCE(TRY_TO_NUMBER(REGEXP_SUBSTR(r , '\\d+')), 0))         AS total_runs,
        SUM(COALESCE(TRY_TO_NUMBER(REGEXP_SUBSTR(h , '\\d+')), 0))         AS total_hits,
        SUM(COALESCE(TRY_TO_NUMBER(REGEXP_SUBSTR(hr, '\\d+')), 0))         AS total_hr
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY player_id
),
max_values AS (
    SELECT
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM career_totals
)
SELECT 'Games Played' AS stat,
       p.name_given   AS name_given,
       c.total_games  AS score
FROM career_totals c
JOIN max_values m               ON c.total_games = m.max_games
JOIN BASEBALL.BASEBALL.PLAYER p ON p.player_id  = c.player_id

UNION ALL
SELECT 'Runs',
       p.name_given,
       c.total_runs
FROM career_totals c
JOIN max_values m               ON c.total_runs = m.max_runs
JOIN BASEBALL.BASEBALL.PLAYER p ON p.player_id  = c.player_id

UNION ALL
SELECT 'Hits',
       p.name_given,
       c.total_hits
FROM career_totals c
JOIN max_values m               ON c.total_hits = m.max_hits
JOIN BASEBALL.BASEBALL.PLAYER p ON p.player_id  = c.player_id

UNION ALL
SELECT 'Home Runs',
       p.name_given,
       c.total_hr
FROM career_totals c
JOIN max_values m               ON c.total_hr = m.max_hr
JOIN BASEBALL.BASEBALL.PLAYER p ON p.player_id  = c.player_id

ORDER BY stat;