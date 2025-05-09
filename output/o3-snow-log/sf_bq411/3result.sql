/*  Retrieve the #1-#3 Google-Trends search terms for each weekday (Mon–Fri)
    whose “week” falls between 01-Sep-2024 and 14-Sep-2024.
    – Keep only weekday snapshots  (DAYOFWEEK 1-5 → Mon-Fri).
    – Pick one term per refresh_date / rank (highest score, tie-break by name).
    – Show newest refresh_date first, then rank 1-3.
*/
WITH weekday_top AS (
    SELECT
        "refresh_date",
        "week",
        "rank",
        "term",
        ROW_NUMBER() OVER (
            PARTITION BY "refresh_date", "rank"
            ORDER BY "score" DESC NULLS LAST, "term"
        ) AS rn
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
    WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
      AND DAYOFWEEK("refresh_date") BETWEEN 1 AND 5   -- Monday (1) … Friday (5)
      AND "rank" IN (1, 2, 3)
)
SELECT
    "refresh_date",
    "week",
    "rank",
    "term"
FROM weekday_top
WHERE rn = 1                       -- keep the single best row per refresh_date / rank
ORDER BY
    "refresh_date" DESC NULLS LAST,
    "rank";