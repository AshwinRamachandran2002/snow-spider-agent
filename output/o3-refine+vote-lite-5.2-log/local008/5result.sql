WITH totals AS (
    SELECT 
        player_id,
        SUM(CAST(COALESCE(g ,0)  AS INTEGER))  AS gp,
        SUM(CAST(COALESCE(r ,0)  AS INTEGER))  AS runs,
        SUM(CAST(COALESCE(h ,0)  AS INTEGER))  AS hits,
        SUM(CAST(COALESCE(hr,0)  AS INTEGER))  AS hr
    FROM batting
    GROUP BY player_id
)
-- highest‑value holders for each category
SELECT 'games_played' AS stat,
       pl.name_given   AS player_name,
       t.gp            AS value
FROM totals t
JOIN player pl ON pl.player_id = t.player_id
WHERE t.gp = (SELECT MAX(gp) FROM totals)

UNION ALL
SELECT 'runs' ,
       pl.name_given ,
       t.runs
FROM totals t
JOIN player pl ON pl.player_id = t.player_id
WHERE t.runs = (SELECT MAX(runs) FROM totals)

UNION ALL
SELECT 'hits' ,
       pl.name_given ,
       t.hits
FROM totals t
JOIN player pl ON pl.player_id = t.player_id
WHERE t.hits = (SELECT MAX(hits) FROM totals)

UNION ALL
SELECT 'home_runs' ,
       pl.name_given ,
       t.hr
FROM totals t
JOIN player pl ON pl.player_id = t.player_id
WHERE t.hr = (SELECT MAX(hr) FROM totals)
ORDER BY stat, player_name;