WITH all_words AS (                       -- keep only words that are 4-5 characters long
    SELECT "words"
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE LENGTH("words") BETWEEN 4 AND 5
),
chars AS (                                -- break each word into its individual characters
    SELECT
        aw."words",
        SUBSTR(aw."words", pos, 1) AS ch
    FROM all_words aw
    JOIN LATERAL (
        SELECT SEQ4() + 1 AS pos          -- generate positions 1-5
        FROM TABLE(GENERATOR(ROWCOUNT => 5))
    ) g
      ON pos <= LENGTH(aw."words")
),
canon AS (                                -- build a canonical, alphabetically-sorted version of each word
    SELECT
        "words",
        LISTAGG(ch, '') WITHIN GROUP (ORDER BY ch) AS canon
    FROM chars
    GROUP BY "words"
),
canon_counts AS (                         -- keep only canonical forms that appear more than once (i.e. have anagrams)
    SELECT
        canon,
        COUNT(*) AS anagram_count
    FROM canon
    GROUP BY canon
    HAVING COUNT(*) > 1
),
candidate AS (                            -- restrict to words starting with 'r'
    SELECT
        c."words"     AS word,
        cc.anagram_count
    FROM canon c
    JOIN canon_counts cc
      ON c.canon = cc.canon
    WHERE c."words" LIKE 'r%'
)
SELECT word,
       anagram_count
FROM candidate
ORDER BY word
LIMIT 10;