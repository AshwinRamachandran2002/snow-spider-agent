WITH depth_calc AS (
    SELECT
        LOWER(REGEXP_SUBSTR("path", '\\.[^./]+$'))          AS "file_type",   -- file extension
        REGEXP_COUNT("path", '/')                           AS "dir_depth"   -- number of “/” = depth
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
), filtered AS (
    SELECT
        "file_type"
    FROM
        depth_calc
    WHERE
        "file_type" IN ('.py', '.c', '.ipynb', '.java', '.js')   -- only required types
        AND "dir_depth" > 10                                     -- depth greater than 10
)
SELECT
    "file_type",
    COUNT(*) AS "file_count"
FROM
    filtered
GROUP BY
    "file_type"
ORDER BY
    "file_count" DESC NULLS LAST,
    "file_type"
LIMIT 1;