SELECT
    "PackageName",
    COUNT(*) AS "ImportCount"
FROM (
    SELECT
        REGEXP_SUBSTR(
            TRIM(f.VALUE),
            'import(\\s+static)?\\s+([a-zA-Z0-9_\\.]+)\\.(\\w+|\\*)\\s*;',
            1,
            1,
            '',
            2
        ) AS "PackageName"
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
        LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
    WHERE
        sc."sample_path" LIKE '%.java'
        AND TRIM(f.VALUE) LIKE 'import %'
)
WHERE
    "PackageName" IS NOT NULL
GROUP BY
    "PackageName"
ORDER BY
    "ImportCount" DESC NULLS LAST
LIMIT 10;