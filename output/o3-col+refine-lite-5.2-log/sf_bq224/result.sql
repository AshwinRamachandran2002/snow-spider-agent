SELECT
    a."repo_name",
    a."total_activity",
    l."license"
FROM (
    /* 1️⃣ Aggregate April‑2022 activity (Forks + Watches + Issues) per repository */
    SELECT
        "repo":"name"::STRING                          AS "repo_name",
        SUM(IFF("type" = 'ForkEvent'  , 1, 0)) +
        SUM(IFF("type" = 'WatchEvent' , 1, 0)) +
        SUM(IFF("type" = 'IssuesEvent', 1, 0))        AS "total_activity"
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE  "created_at" BETWEEN 1648771200000000      -- 01‑Apr‑2022 00:00 UTC (µs)
                           AND     1651363200000000      -- 01‑May‑2022 00:00 UTC (µs)
      AND  "type" IN ('ForkEvent','WatchEvent','IssuesEvent')
    GROUP BY "repo":"name"
) a
/* 2️⃣ Keep only repositories whose license string is one of the SPDX / OSI‑approved codes */
JOIN   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES" l
       ON a."repo_name" = l."repo_name"
WHERE  l."license" IN (
          'apache-2.0','mit','bsd-3-clause','bsd-2-clause','gpl-2.0','gpl-3.0',
          'lgpl-2.1','lgpl-3.0','mpl-2.0','epl-1.0','agpl-3.0',
          'cc0-1.0','unlicense','isc','artistic-2.0'
      )
/* 3️⃣ Return the single repository with the highest combined activity */
ORDER BY a."total_activity" DESC NULLS LAST
LIMIT 1;