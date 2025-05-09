WITH joined AS (   -- bring together file meta‑data and non‑binary contents
    SELECT
        CASE
            WHEN f."path" ILIKE '%.py' THEN 'python'
            WHEN f."path" ILIKE '%.r'  THEN 'r'
        END                    AS "lang",
        c."content"            AS "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON f."id" = c."id"
    WHERE (f."path" ILIKE '%.py' OR f."path" ILIKE '%.r')
      AND c."binary" = FALSE
),
lines AS (        -- split every file into individual source lines
    SELECT
        "lang",
        line.value::STRING AS "line_txt"
    FROM joined,
         LATERAL FLATTEN(input => SPLIT("content", '\n')) line
),
captured AS (     -- pull out module / package names with regex
        /* -------- Python:  plain  “import xxx” -------- */
    SELECT 'python' AS "lang",
           REGEXP_SUBSTR("line_txt",
                         'import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'i', 1) AS "mod"
      FROM lines
     WHERE "lang" = 'python'
       AND "line_txt" ILIKE '%import %'

    UNION ALL
        /* -------- Python:  “from xxx import …” -------- */
    SELECT 'python' AS "lang",
           REGEXP_SUBSTR("line_txt",
                         'from\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'i', 1) AS "mod"
      FROM lines
     WHERE "lang" = 'python'
       AND "line_txt" ILIKE '%from %import%'

    UNION ALL
        /* -------- R: library() / require() calls -------- */
    SELECT 'r'      AS "lang",
           REGEXP_SUBSTR("line_txt",
                         '(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)', 1, 1, 'i', 2) AS "mod"
      FROM lines
     WHERE "lang" = 'r'
       AND ("line_txt" ILIKE '%library(%' OR "line_txt" ILIKE '%require(%')
)
SELECT
    "lang",
    UPPER("mod")        AS "module_or_package",
    COUNT(*)            AS "occurrences"
FROM captured
WHERE "mod" IS NOT NULL
GROUP BY "lang", UPPER("mod")
ORDER BY "lang", "occurrences" DESC NULLS LAST;