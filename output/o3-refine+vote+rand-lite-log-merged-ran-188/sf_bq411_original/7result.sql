SELECT
    "refresh_date",
    "rank",
    "term"
FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_TERMS"
WHERE DATEADD(DAY, 1, "week") BETWEEN DATE '2024-09-02' AND DATE '2024-09-13'  -- Monday‑to‑Friday window
  AND "rank" IN (1, 2, 3)                                                       -- top three terms
ORDER BY
    "refresh_date" DESC NULLS LAST,                                             -- latest refresh first
    "rank" ASC,                                                                 -- rank 1, 2, 3
    "term" ASC;                                                                 -- tie‑breaker