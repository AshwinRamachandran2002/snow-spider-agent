WITH april22_filtered AS (
    SELECT
        "repo":"name"::string AS repo_name
    FROM   GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE  "created_at" >= 1648771200000000        -- 2022‑04‑01 00:00:00 UTC
      AND  "created_at" <  1651363200000000        -- 2022‑05‑01 00:00:00 UTC
      AND  "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent')
      AND  "repo":"name"::string IN (               -- keep only approved‑license repos
              SELECT "repo_name"
              FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
              WHERE  "license" IS NOT NULL
          )
)
SELECT  repo_name,
        COUNT(*) AS combined_total
FROM    april22_filtered
GROUP BY repo_name
ORDER BY combined_total DESC NULLS LAST,
         repo_name
LIMIT 1;