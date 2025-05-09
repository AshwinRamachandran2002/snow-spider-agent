WITH joined_files AS (          /* keep only files that have non-empty content */
    SELECT
        f."path"                               AS file_path,
        SPLIT_PART(f."path", '/', -1)          AS file_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(TRIM(c."content")) > 0
),
files_with_lang AS (           /* map each file to a recognised language */
    SELECT
        CASE
            WHEN LOWER(file_name) = 'dockerfile'
                 OR REGEXP_LIKE(LOWER(file_name), '.*\.dockerfile$')              THEN 'Dockerfile'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(asm|nasm)$')                 THEN 'Assembly'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.c$')                          THEN 'C'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(c\+\+|cpp|h\+\+|hpp)$')      THEN 'C++'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.cs$')                         THEN 'C#'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.css$')                        THEN 'CSS'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.clj$')                        THEN 'Clojure'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.lisp$')                       THEN 'Common Lisp'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.d$')                          THEN 'D'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.dart$')                       THEN 'Dart'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(ex|exs)$')                   THEN 'Elixir'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.erl$')                        THEN 'Erlang'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.go$')                         THEN 'Go'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.groovy$')                     THEN 'Groovy'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(html?|htm)$')                THEN 'HTML'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.hs$')                         THEN 'Haskell'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.hx$')                         THEN 'Haxe'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.json$')                       THEN 'JSON'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.java$')                       THEN 'Java'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(js|cjs)$')                   THEN 'JavaScript'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.jl$')                         THEN 'Julia'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(kt|ktm|kts)$')               THEN 'Kotlin'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.lua$')                        THEN 'Lua'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(matlab|m)$')                 THEN 'MATLAB'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(md|markdown|mdown)$')        THEN 'Markdown'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.php$')                        THEN 'PHP'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(ps1|psd1|psm1)$')            THEN 'PowerShell'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.py$')                         THEN 'Python'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.r$')                          THEN 'R'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.rb$')                         THEN 'Ruby'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.rs$')                         THEN 'Rust'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.scss$')                       THEN 'SCSS'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.sql$')                        THEN 'SQL'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.sass$')                       THEN 'Sass'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.scala$')                      THEN 'Scala'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.(sh|bash)$')                  THEN 'Shell'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.swift$')                      THEN 'Swift'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.ts$')                         THEN 'TypeScript'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.vue$')                        THEN 'Vue'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.xml$')                        THEN 'XML'
            WHEN REGEXP_LIKE(LOWER(file_name), '.*\.ya?ml$')                      THEN 'YAML'
            ELSE NULL
        END AS language
    FROM joined_files
)
SELECT
    language,
    COUNT(*) AS file_count
FROM files_with_lang
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST
LIMIT 10;