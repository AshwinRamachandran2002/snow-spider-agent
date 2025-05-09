WITH base_words AS (   -- 4–5 characters, begin with lowercase “r”
    SELECT "words" AS word
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE REGEXP_LIKE("words", '^r.{3,4}$')
),
char_split AS (        -- split each word into its characters (max length needed = 5)
    SELECT
        bw.word,
        SUBSTR(bw.word, g.seq + 1, 1) AS ch
    FROM base_words bw,
         LATERAL (
             SELECT SEQ4() AS seq
             FROM TABLE(GENERATOR(ROWCOUNT => 5))   -- constant rowcount avoids error
         ) g
    WHERE g.seq < LENGTH(bw.word)                   -- keep only existing character positions
),
word_signatures AS (   -- build a sorted-character signature for every word
    SELECT
        word,
        LISTAGG(ch, '') WITHIN GROUP (ORDER BY ch) AS signature
    FROM char_split
    GROUP BY word
),
signature_groups AS (  -- retain only signatures shared by ≥2 words (i.e., anagrams exist)
    SELECT
        signature,
        COUNT(*) AS group_size
    FROM word_signatures
    GROUP BY signature
    HAVING COUNT(*) > 1
),
eligible_words AS (    -- attach anagram count (excluding the word itself)
    SELECT
        ws.word,
        sg.group_size - 1 AS anagram_count
    FROM word_signatures ws
    JOIN signature_groups sg
      ON ws.signature = sg.signature
)
SELECT
    word,
    anagram_count
FROM eligible_words
ORDER BY word
LIMIT 10;