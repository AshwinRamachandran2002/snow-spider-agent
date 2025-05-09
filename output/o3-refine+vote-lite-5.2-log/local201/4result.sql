WITH
filtered AS (            -- 1) keep only 4‑5 letter words that start with  'r'
    SELECT words
    FROM word_list
    WHERE substr(words,1,1) = 'r'
      AND length(words) BETWEEN 4 AND 5
),
chars AS (               -- 2) split every word into single characters
    SELECT words,
           1 AS pos,
           substr(words,1,1) AS ch,
           length(words)     AS len
    FROM filtered
  UNION ALL
    SELECT words,
           pos+1,
           substr(words,pos+1,1),
           len
    FROM chars
    WHERE pos < len
),
sorted_key AS (          -- 3) build an alphabetical “signature” for every word
    SELECT  words,
            GROUP_CONCAT(ch, '') AS sig          -- characters sorted A‑Z
    FROM    ( SELECT words, ch
              FROM   chars
              ORDER  BY words, ch )              -- order chars before concatenating
    GROUP BY words
),
anagram_sets AS (        -- 4) keep only signatures that occur in ≥ 2 words
    SELECT  sig,
            COUNT(*) AS anagram_cnt
    FROM    sorted_key
    GROUP BY sig
    HAVING  COUNT(*) > 1
),
wanted AS (              -- 5) attach the anagram counts to the individual words
    SELECT  sk.words,
            a.anagram_cnt
    FROM    sorted_key AS sk
    JOIN    anagram_sets AS a
           ON a.sig = sk.sig
)
SELECT  words,
        anagram_cnt                     -- number of words that share the signature
FROM    wanted
ORDER BY words
LIMIT 10;                               -- first 10 alphabetically