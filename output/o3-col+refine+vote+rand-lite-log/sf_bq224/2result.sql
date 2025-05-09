/* Repository (with an approved license from any license*.md file)
   that accumulated the most ForkEvent + WatchEvent + IssuesEvent
   occurrences during April 2022 */

WITH approved_tokens AS (          -- possible SPDX ids extracted from *.md license files
    SELECT DISTINCT
           LOWER(TRIM(tok.value::string)) AS token
    FROM  "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
          LATERAL FLATTEN(
              INPUT => SPLIT(
                  REGEXP_REPLACE(sc."content", '[`*\\-\\n]', ' '),  -- strip md markers/new-lines
                  ' '
              )
          ) tok
    WHERE  LOWER(sc."sample_path") LIKE '%license%'        -- path contains “license”
      AND  LOWER(sc."sample_path") LIKE '%.md'             -- markdown files only
      AND  tok.value IS NOT NULL
      AND  LENGTH(TRIM(tok.value::string)) <= 20           -- keep short candidates
),
repos_with_approved_license AS (   -- repos whose declared license matches a token above
    SELECT l."repo_name" AS repo_name
    FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES" l
    JOIN   approved_tokens t
      ON   LOWER(l."license") = t.token
),
april_2022_events AS (             -- Fork/Watch/Issue events in April-2022
    SELECT "repo":"name"::string AS repo_name
    FROM   "GITHUB_REPOS_DATE"."YEAR"."_2022"
    WHERE  "type" IN ('ForkEvent', 'WatchEvent', 'IssuesEvent')
      AND  TO_VARCHAR(TO_TIMESTAMP_LTZ("created_at" / 1000000), 'YYYY-MM') = '2022-04'
)
SELECT   e.repo_name,
         COUNT(*) AS total_forks_issues_watches
FROM     april_2022_events         e
JOIN     repos_with_approved_license r
       ON e.repo_name = r.repo_name
GROUP BY e.repo_name
ORDER BY total_forks_issues_watches DESC NULLS LAST
LIMIT 1;