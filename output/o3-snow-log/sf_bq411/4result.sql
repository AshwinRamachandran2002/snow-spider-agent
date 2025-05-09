SELECT
    "refresh_date",
    "week",
    "rank",
    "term"
FROM
    GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_TERMS
WHERE
    "week" BETWEEN '2024-09-01' AND '2024-09-14'      -- target weeks
    AND DAYOFWEEKISO("refresh_date") BETWEEN 1 AND 5  -- Monday (1) … Friday (5)
    AND "rank" IN (1, 2, 3)                           -- top-three terms
ORDER BY
    "refresh_date" DESC NULLS LAST,
    "week",
    "rank";