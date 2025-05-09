WITH metrics AS (
    SELECT
        "PLAYER_ID",
        "G"                                        AS g_val,
        TRY_TO_NUMBER("R")                         AS r_val,
        TRY_TO_NUMBER("H")                         AS h_val,
        TRY_TO_NUMBER("HR")                        AS hr_val
    FROM BASEBALL.BASEBALL.BATTING
),
max_vals AS (
    SELECT
        MAX(g_val)  AS max_g,
        MAX(r_val)  AS max_r,
        MAX(h_val)  AS max_h,
        MAX(hr_val) AS max_hr
    FROM metrics
)
SELECT 'GAMES_PLAYED' AS "metric",
       p."NAME_GIVEN" AS "name_given",
       m.g_val        AS "value"
FROM metrics m
JOIN max_vals v                 ON m.g_val = v.max_g
JOIN BASEBALL.BASEBALL.PLAYER p ON p."PLAYER_ID" = m."PLAYER_ID"

UNION ALL

SELECT 'RUNS'       AS "metric",
       p."NAME_GIVEN",
       m.r_val       AS "value"
FROM metrics m
JOIN max_vals v                 ON m.r_val = v.max_r
JOIN BASEBALL.BASEBALL.PLAYER p ON p."PLAYER_ID" = m."PLAYER_ID"

UNION ALL

SELECT 'HITS'       AS "metric",
       p."NAME_GIVEN",
       m.h_val       AS "value"
FROM metrics m
JOIN max_vals v                 ON m.h_val = v.max_h
JOIN BASEBALL.BASEBALL.PLAYER p ON p."PLAYER_ID" = m."PLAYER_ID"

UNION ALL

SELECT 'HOME_RUNS'  AS "metric",
       p."NAME_GIVEN",
       m.hr_val      AS "value"
FROM metrics m
JOIN max_vals v                 ON m.hr_val = v.max_hr
JOIN BASEBALL.BASEBALL.PLAYER p ON p."PLAYER_ID" = m."PLAYER_ID"

ORDER BY "metric";