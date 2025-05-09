WITH valid_players AS (
    SELECT "debut", "final_game"
    FROM player
    WHERE LENGTH("debut") = 10
      AND LENGTH("final_game") = 10
),
span_parts AS (
    SELECT
        ROUND(ABS(CAST(SUBSTR("final_game",1,4) AS INTEGER) -
                  CAST(SUBSTR("debut",1,4)  AS INTEGER)), 2)                         AS yr,
        ROUND(ABS(CAST(SUBSTR("final_game",6,2) AS INTEGER) -
                  CAST(SUBSTR("debut",6,2)  AS INTEGER)) / 12.0, 2)                 AS mo,
        ROUND(ABS(CAST(SUBSTR("final_game",9,2) AS INTEGER) -
                  CAST(SUBSTR("debut",9,2)  AS INTEGER)) / 365.0, 2)                AS dy
    FROM valid_players
),
career_span AS (
    SELECT (yr + mo + dy) AS span_years
    FROM span_parts
)
SELECT ROUND(AVG(span_years), 4) AS career_span_avg_years
FROM career_span;