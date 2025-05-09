SELECT
  '2023-01-18' AS "event_date",
  COUNT(*)     AS "pull_request_creation_events"
FROM (
  /* pull‑request creation events on 18‑Jan‑2023 */
  SELECT y."repo":"name"::STRING AS "repo_name"
  FROM   "GITHUB_REPOS_DATE"."YEAR"."_2023" y
  WHERE  y."type" = 'PullRequestEvent'
    AND  PARSE_JSON(y."payload"):"action"::STRING = 'opened'
    AND  y."created_at" BETWEEN 1674000000000000 AND 1674086399999999  -- 2023‑01‑18 UTC (µs)
) pr
JOIN (
  /* repositories that include JavaScript among their languages */
  SELECT DISTINCT l."repo_name"
  FROM   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(INPUT => l."language") lang
  WHERE  lang.value:"name"::STRING = 'JavaScript'
) js
  ON js."repo_name" = pr."repo_name";