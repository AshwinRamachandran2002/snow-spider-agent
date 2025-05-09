WITH career AS (
    SELECT 
        player_id,
        SUM(g)  AS tot_games,
        SUM(r)  AS tot_runs,
        SUM(h)  AS tot_hits,
        SUM(hr) AS tot_hr
    FROM batting
    GROUP BY player_id
),
max_vals AS (
    SELECT 
        MAX(tot_games) AS max_games,
        MAX(tot_runs)  AS max_runs,
        MAX(tot_hits)  AS max_hits,
        MAX(tot_hr)    AS max_hr
    FROM career
)
SELECT 
    p.name_given AS given_name,
    c.tot_games  AS score_value,
    'Most Games Played' AS category
FROM career c
JOIN player p ON p.player_id = c.player_id
JOIN max_vals m
WHERE c.tot_games = m.max_games

UNION ALL

SELECT 
    p.name_given,
    c.tot_runs,
    'Most Runs'
FROM career c
JOIN player p ON p.player_id = c.player_id
JOIN max_vals m
WHERE c.tot_runs = m.max_runs

UNION ALL

SELECT 
    p.name_given,
    c.tot_hits,
    'Most Hits'
FROM career c
JOIN player p ON p.player_id = c.player_id
JOIN max_vals m
WHERE c.tot_hits = m.max_hits

UNION ALL

SELECT 
    p.name_given,
    c.tot_hr,
    'Most Home Runs'
FROM career c
JOIN player p ON p.player_id = c.player_id
JOIN max_vals m
WHERE c.tot_hr = m.max_hr;