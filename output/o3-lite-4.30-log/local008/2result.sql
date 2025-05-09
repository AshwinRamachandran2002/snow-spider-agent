WITH max_vals AS (
    SELECT
        (SELECT MAX(g) FROM batting WHERE g IS NOT NULL)                                      AS max_g,
        (SELECT MAX(CAST(r  AS INTEGER)) FROM batting WHERE r  IS NOT NULL AND r  <> '')     AS max_r,
        (SELECT MAX(CAST(h  AS INTEGER)) FROM batting WHERE h  IS NOT NULL AND h  <> '')     AS max_h,
        (SELECT MAX(CAST(hr AS INTEGER)) FROM batting WHERE hr IS NOT NULL AND hr <> '')     AS max_hr
)
SELECT DISTINCT p.name_given AS given_name,
       'games'               AS statistic,
       mv.max_g              AS max_value
FROM   batting b
JOIN   player  p USING(player_id)
JOIN   max_vals mv
WHERE  b.g = mv.max_g

UNION ALL
SELECT DISTINCT p.name_given,
       'runs',
       mv.max_r
FROM   batting b
JOIN   player  p USING(player_id)
JOIN   max_vals mv
WHERE  CAST(b.r AS INTEGER) = mv.max_r

UNION ALL
SELECT DISTINCT p.name_given,
       'hits',
       mv.max_h
FROM   batting b
JOIN   player  p USING(player_id)
JOIN   max_vals mv
WHERE  CAST(b.h AS INTEGER) = mv.max_h

UNION ALL
SELECT DISTINCT p.name_given,
       'home_runs',
       mv.max_hr
FROM   batting b
JOIN   player  p USING(player_id)
JOIN   max_vals mv
WHERE  CAST(b.hr AS INTEGER) = mv.max_hr;