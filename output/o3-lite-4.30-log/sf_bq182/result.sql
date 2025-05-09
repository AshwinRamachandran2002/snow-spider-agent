WITH day_pr_events AS (
    SELECT
        t."repo":name::STRING AS repo_name,
        COUNT(*)              AS pr_events
    FROM GITHUB_REPOS_DATE.YEAR."_2023" t
    WHERE t."type" = 'PullRequestEvent'
      AND t."created_at" BETWEEN 1674000000000000   -- 2023‑01‑18 00:00:00 UTC
                           AND 1674086399999999   -- 2023‑01‑18 23:59:59 UTC
      AND t."repo":name IS NOT NULL
    GROUP BY repo_name
),
primary_language AS (
    SELECT
        l."repo_name",
        FIRST_VALUE(f.value:"name"::STRING)
            OVER (PARTITION BY l."repo_name"
                  ORDER BY f.value:"bytes"::INT DESC) AS language
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
)
SELECT
    pl.language
FROM day_pr_events  d
JOIN primary_language pl
  ON d.repo_name = pl."repo_name"
GROUP BY pl.language
HAVING SUM(d.pr_events) >= 100
ORDER BY pl.language;