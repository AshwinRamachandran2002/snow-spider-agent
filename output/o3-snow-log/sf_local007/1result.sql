WITH player_dates AS (
    SELECT
        "PLAYER_ID"                         AS PLAYER_ID,
        TRY_TO_DATE("DEBUT")                AS DEBUT_DATE,
        TRY_TO_DATE("FINAL_GAME")           AS FINAL_DATE
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE TRY_TO_DATE("DEBUT")      IS NOT NULL
      AND TRY_TO_DATE("FINAL_GAME") IS NOT NULL
),
date_parts AS (
    SELECT
        PLAYER_ID,
        ABS(DATEDIFF('year',  DEBUT_DATE, FINAL_DATE))                                                           AS YRS,
        ABS(DATEDIFF('month',
                     DATEADD('year',  DATEDIFF('year',  DEBUT_DATE, FINAL_DATE), DEBUT_DATE),
                     FINAL_DATE))                                                                                AS MOS,
        ABS(DATEDIFF('day',
                     DATEADD('month',
                             DATEDIFF('month',
                                      DATEADD('year', DATEDIFF('year', DEBUT_DATE, FINAL_DATE), DEBUT_DATE),
                                      FINAL_DATE),
                             DATEADD('year', DATEDIFF('year', DEBUT_DATE, FINAL_DATE), DEBUT_DATE)
                            ),
                     FINAL_DATE))                                                                                AS DYS
    FROM player_dates
),
career_spans AS (
    SELECT
        PLAYER_ID,
        ROUND(YRS::NUMBER, 2) +
        ROUND(MOS::NUMBER / 12, 2) +
        ROUND(DYS::NUMBER / 365, 2)                                                                              AS SPAN
    FROM date_parts
)
SELECT
    ROUND(AVG(SPAN), 4) AS AVERAGE_CAREER_SPAN
FROM career_spans;