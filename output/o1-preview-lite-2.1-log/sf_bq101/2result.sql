SELECT
    "Package",
    COUNT(*) AS "Count"
FROM (
    SELECT
        REGEXP_REPLACE(
            REGEXP_SUBSTR(line.value, '^import\\s+([\\w\\.]+)', 1, 1, 'e', 1),
            '^import\\s+',
            ''
        ) AS "Package"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS line
    WHERE f."path" LIKE '%.java' AND c."binary" = FALSE
        AND line.value ILIKE 'import %'
)
WHERE "Package" IS NOT NULL
GROUP BY "Package"
ORDER BY "Count" DESC NULLS LAST
LIMIT 10;