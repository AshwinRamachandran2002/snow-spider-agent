WITH player_dates AS (
    SELECT
        "PLAYER_ID",
        TO_DATE("DEBUT")       AS debut_date,
        TO_DATE("FINAL_GAME")  AS final_date
    FROM BASEBALL.BASEBALL.PLAYER
    WHERE "DEBUT" IS NOT NULL      AND TRIM("DEBUT")      <> ''
      AND "FINAL_GAME" IS NOT NULL AND TRIM("FINAL_GAME") <> ''
),
tot_months AS (  -- total whole-month difference between debut and final game
    SELECT
        "PLAYER_ID",
        debut_date,
        final_date,
        ABS(DATEDIFF(month, debut_date, final_date)) AS total_months
    FROM player_dates
),
date_parts AS (  -- split total months into years, months, and residual days
    SELECT
        "PLAYER_ID",
        FLOOR(total_months / 12)                              AS years_part,
        (total_months - FLOOR(total_months / 12) * 12)        AS months_part,
        ABS(
            DATEDIFF(
                day,
                DATEADD(
                    month, (total_months - FLOOR(total_months / 12) * 12),
                    DATEADD(year, FLOOR(total_months / 12), debut_date)
                ),
                final_date
            )
        ) AS days_part
    FROM tot_months
),
career_span AS (  -- compute rounded span for each player
    SELECT
        "PLAYER_ID",
        ROUND(years_part::FLOAT, 2) +
        ROUND(months_part / 12.0, 2) +
        ROUND(days_part   / 365.0, 2) AS span_years
    FROM date_parts
)
SELECT
    ROUND(AVG(span_years), 4) AS avg_career_span_years
FROM career_span;