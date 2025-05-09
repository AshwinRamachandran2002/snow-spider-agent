SELECT
    w1."words"                             AS word,
    COUNT(DISTINCT w2."words")             AS anagram_count
FROM   "word_list" AS w1
JOIN   "word_list" AS w2
       ON  w1."words" <> w2."words"
       AND LENGTH(w1."words") = LENGTH(w2."words")
       -- same-length, case–sensitive letter-frequency match
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'a',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'a','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'b',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'b','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'c',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'c','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'d',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'d','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'e',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'e','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'f',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'f','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'g',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'g','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'h',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'h','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'i',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'i','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'j',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'j','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'k',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'k','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'l',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'l','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'m',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'m','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'n',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'n','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'o',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'o','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'p',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'p','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'q',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'q','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'r',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'r','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'s',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'s','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'t',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'t','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'u',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'u','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'v',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'v','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'w',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'w','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'x',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'x','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'y',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'y','')))
       AND (LENGTH(w1."words")-LENGTH(REPLACE(w1."words",'z',''))) =
           (LENGTH(w2."words")-LENGTH(REPLACE(w2."words",'z','')))
WHERE  (LENGTH(w1."words") = 4 OR LENGTH(w1."words") = 5)
  AND  w1."words" GLOB 'r*'          -- case-sensitive “starts with r”
GROUP BY w1."words"
HAVING COUNT(DISTINCT w2."words") >= 1
ORDER BY w1."words"
LIMIT 10;