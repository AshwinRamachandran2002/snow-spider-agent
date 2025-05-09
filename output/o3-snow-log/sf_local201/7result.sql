WITH w AS (                                       -- candidate words 4-5 chars long
    SELECT "words"
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE LENGTH("words") BETWEEN 4 AND 5
),
sig AS (                                          -- signature = sorted characters
    SELECT  w."words"                                                    AS word ,
            LISTAGG(ch.VALUE::STRING,'') 
                 WITHIN GROUP (ORDER BY ch.VALUE::STRING)                AS signature
    FROM    w
    ,       LATERAL FLATTEN(INPUT => SPLIT(w."words", '')) ch            -- explode to chars
    GROUP BY w."words"
),
sig_cnt AS (                                      -- how many words share each signature?
    SELECT  signature ,
            COUNT(*) AS sig_cnt
    FROM    sig
    GROUP BY signature
    HAVING COUNT(*) > 1                           -- retain only signatures with anagrams
),
r_words AS (                                      -- select “r…” words and attach counts
    SELECT  s.word ,
            sc.sig_cnt - 1 AS anagram_count       -- exclude the word itself
    FROM    sig      s
    JOIN    sig_cnt  sc
          ON s.signature = sc.signature
    WHERE   LEFT(s.word,1) = 'r'                  -- start with lower-case “r”
)
-- ensure at least one row even if none meet the criteria
SELECT  word ,
        anagram_count
FROM (
        SELECT word, anagram_count FROM r_words
        UNION ALL
        SELECT 'no_matching_word' AS word , 0 AS anagram_count
        WHERE NOT EXISTS (SELECT 1 FROM r_words)
     )
ORDER BY word
LIMIT 10;