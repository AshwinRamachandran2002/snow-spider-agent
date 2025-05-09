WITH base_dates AS (
    SELECT
        "PLAYER_ID",
        TRY_TO_DATE("DEBUT")      AS DEBUT_DT,
        TRY_TO_DATE("FINAL_GAME") AS FINAL_DT
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE TRY_TO_DATE("DEBUT")      IS NOT NULL
      AND TRY_TO_DATE("FINAL_GAME") IS NOT NULL
),
calc AS (
    SELECT
        "PLAYER_ID",
        DEBUT_DT,
        FINAL_DT,
        ABS(DATEDIFF('month', DEBUT_DT, FINAL_DT)) AS TOT_MONTHS,
        /* days remaining after removing whole-months span */
        CASE
            WHEN DEBUT_DT <= FINAL_DT THEN
                 ABS(DATEDIFF(
                     'day',
                     DATEADD('month', ABS(DATEDIFF('month', DEBUT_DT, FINAL_DT)), DEBUT_DT),
                     FINAL_DT))
            ELSE
                 ABS(DATEDIFF(
                     'day',
                     DATEADD('month', ABS(DATEDIFF('month', DEBUT_DT, FINAL_DT)), FINAL_DT),
                     DEBUT_DT))
        END AS DAYS_PART
    FROM base_dates
),
parts AS (
    SELECT
        "PLAYER_ID",
        FLOOR(TOT_MONTHS / 12)         AS YRS_PART,
        MOD(TOT_MONTHS, 12)            AS MTHS_PART,
        DAYS_PART
    FROM calc
),
career_spans AS (
    SELECT
        "PLAYER_ID",
        ROUND(YRS_PART :: NUMBER, 2)             -- years
      + ROUND(MTHS_PART :: NUMBER, 2) / 12       -- months → years
      + ROUND(DAYS_PART :: NUMBER, 2) / 365      -- days   → years
        AS CAREER_SPAN
    FROM parts
)
SELECT ROUND(AVG(CAREER_SPAN), 4) AS AVERAGE_SINGLE_CAREER_SPAN
FROM career_spans;