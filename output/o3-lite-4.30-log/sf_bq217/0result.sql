SELECT
        '2023-01-18'                                             AS "event_date",
        COUNT(*)                                                AS "pull_request_creation_events"
FROM   (
        /* pull‑request “opened” events that happened on 18‑Jan‑2023 */
        SELECT  t."repo":name::STRING AS "repo_name"
        FROM    "GITHUB_REPOS_DATE"."YEAR"."_2023"  t
        WHERE   t."type" = 'PullRequestEvent'
          AND   (PARSE_JSON(t."payload"):action)::STRING = 'opened'
          /* created_at is stored in micro‑seconds since epoch */
          AND   TO_DATE(TO_TIMESTAMP_NTZ(t."created_at" / 1000000)) = '2023-01-18'
      ) pr
JOIN   "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l
       ON pr."repo_name" = l."repo_name"
WHERE  l."language"::STRING ILIKE '%"JavaScript"%';