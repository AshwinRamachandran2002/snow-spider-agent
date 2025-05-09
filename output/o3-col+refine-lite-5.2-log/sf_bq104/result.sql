WITH latest_refresh AS (
    SELECT MAX("refresh_date") AS "refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
), latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "refresh_date" = (SELECT "refresh_date" FROM latest_refresh)
), one_year_prior_week AS (
    SELECT DATEADD(week,-52,"latest_week") AS "target_week"
    FROM latest_week
), candidate_rows AS (
    SELECT
        "term",
        "rank",
        "percent_gain"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
    WHERE "week" = (SELECT "target_week" FROM one_year_prior_week)
), best_rank AS (
    SELECT MIN("rank") AS "min_rank"
    FROM candidate_rows
), top_ranked AS (
    SELECT *
    FROM candidate_rows
    WHERE "rank" = (SELECT "min_rank" FROM best_rank)
)
SELECT
    "term",
    "rank",
    "percent_gain"
FROM top_ranked
QUALIFY ROW_NUMBER() OVER (ORDER BY "percent_gain" DESC NULLS LAST, "term") = 1;