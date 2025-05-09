WITH spans AS (
  SELECT
        "player_id",
        ROUND(ABS(CAST(SUBSTR("final_game",1,4) AS INTEGER) -
                  CAST(SUBSTR("debut",1,4)      AS INTEGER)), 2)                  AS yrs_part,
        ROUND(ABS(CAST(SUBSTR("final_game",6,2) AS INTEGER) -
                  CAST(SUBSTR("debut",6,2)      AS INTEGER)) / 12.0, 2)           AS months_part,
        ROUND(ABS(CAST(SUBSTR("final_game",9,2) AS INTEGER) -
                  CAST(SUBSTR("debut",9,2)      AS INTEGER)) / 365.0, 2)          AS days_part
  FROM   "player"
  WHERE  "debut"      IS NOT NULL AND "debut"      <> ''
     AND "final_game" IS NOT NULL AND "final_game" <> ''
)
SELECT ROUND(AVG(yrs_part + months_part + days_part), 4) AS average_career_span
FROM   spans;