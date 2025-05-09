WITH career AS (
    SELECT 
        "player_id",
        SUM("g")  AS total_games,
        SUM("r")  AS total_runs,
        SUM("h")  AS total_hits,
        SUM("hr") AS total_hr
    FROM "batting"
    GROUP BY "player_id"
), max_vals AS (
    SELECT 
        MAX(total_games) AS max_games,
        MAX(total_runs)  AS max_runs,
        MAX(total_hits)  AS max_hits,
        MAX(total_hr)    AS max_hr
    FROM career
)
SELECT 'Games Played' AS category, p."name_given", c.total_games AS value
FROM career c
JOIN "player" p ON p."player_id" = c."player_id"
JOIN max_vals mv ON c.total_games = mv.max_games

UNION ALL
SELECT 'Runs', p."name_given", c.total_runs
FROM career c
JOIN "player" p ON p."player_id" = c."player_id"
JOIN max_vals mv ON c.total_runs = mv.max_runs

UNION ALL
SELECT 'Hits', p."name_given", c.total_hits
FROM career c
JOIN "player" p ON p."player_id" = c."player_id"
JOIN max_vals mv ON c.total_hits = mv.max_hits

UNION ALL
SELECT 'Home Runs', p."name_given", c.total_hr
FROM career c
JOIN "player" p ON p."player_id" = c."player_id"
JOIN max_vals mv ON c.total_hr = mv.max_hr

ORDER BY category;