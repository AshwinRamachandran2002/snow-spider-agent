WITH lang_expanded AS (
    SELECT
        l."repo_name",
        /* language name can come from either the key (map form)
           or the "name" field inside an object (array‑of‑objects form) */
        CASE
            WHEN TYPEOF(f.value) = 'OBJECT' THEN f.value:"name"::string
            ELSE f.key::string
        END                                                   AS "language",
        /* byte count can come from either the "bytes" field in the object
           or directly from the value (map form) */
        CASE
            WHEN TYPEOF(f.value) = 'OBJECT' THEN f.value:"bytes"::number
            WHEN TYPEOF(f.value) = 'NUMBER' THEN f.value::number
            ELSE NULL
        END                                                   AS "bytes"
    FROM GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" l,
         LATERAL FLATTEN(INPUT => l."language") f
),
primary_language AS (
    SELECT
        "repo_name",
        "language",
        ROW_NUMBER() OVER (PARTITION BY "repo_name"
                           ORDER BY "bytes" DESC NULLS LAST) AS rn
    FROM lang_expanded
)
SELECT
    p."repo_name",
    COUNT(c."commit") AS "commit_count"
FROM primary_language p
JOIN GITHUB_REPOS.GITHUB_REPOS."SAMPLE_COMMITS" c
  ON p."repo_name" = c."repo_name"
WHERE
    p.rn = 1
    AND LOWER(p."language") = 'javascript'   -- primary language is JavaScript
GROUP BY
    p."repo_name"
ORDER BY
    "commit_count" DESC NULLS LAST,
    p."repo_name"
LIMIT 2;