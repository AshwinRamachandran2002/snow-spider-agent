/*  -----------------------------------------
    Clones that simultaneously show
      1) LOSS on chr13 (48 303 751‑48 481 890)
      2) LOSS on chr17 ( 7 668 421‑ 7 687 490)
      3) GAIN on chr11 (108 223 067‑108 369 102)
    and their karyotype description
    ----------------------------------------- */
WITH clones_with_all_three AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
        (ChrOrd = 13 AND Type = 'Loss'
         AND `Start` <= 48303751  AND `End` >= 48481890)
     OR (ChrOrd = 17 AND Type = 'Loss'
         AND `Start` <=  7668421  AND `End` >=  7687490)
     OR (ChrOrd = 11 AND Type = 'Gain'
         AND `Start` <=108223067 AND `End` >=108369102)
  GROUP BY RefNo, CaseNo, InvNo, Clone
  HAVING
        COUNTIF(ChrOrd = 13 AND Type = 'Loss'
                AND `Start` <= 48303751  AND `End` >= 48481890)  > 0
    AND COUNTIF(ChrOrd = 17 AND Type = 'Loss'
                AND `Start` <=  7668421  AND `End` >=  7687490)  > 0
    AND COUNTIF(ChrOrd = 11 AND Type = 'Gain'
                AND `Start` <=108223067 AND `End` >=108369102)  > 0
),

-- choose the widest interval per clone for each abnormality
chr13_loss AS (
  SELECT *
  FROM (
    SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY (`End`-`Start`) DESC) AS rn
    FROM `mitelman-db.prod.CytoConverted`
    WHERE ChrOrd = 13 AND Type = 'Loss'
      AND `Start` <= 48303751 AND `End` >= 48481890
  )
  WHERE rn = 1
),

chr17_loss AS (
  SELECT *
  FROM (
    SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY (`End`-`Start`) DESC) AS rn
    FROM `mitelman-db.prod.CytoConverted`
    WHERE ChrOrd = 17 AND Type = 'Loss'
      AND `Start` <= 7668421 AND `End` >= 7687490
  )
  WHERE rn = 1
),

chr11_gain AS (
  SELECT *
  FROM (
    SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY (`End`-`Start`) DESC) AS rn
    FROM `mitelman-db.prod.CytoConverted`
    WHERE ChrOrd = 11 AND Type = 'Gain'
      AND `Start` <= 108223067 AND `End` >= 108369102
  )
  WHERE rn = 1
)

SELECT
  c.RefNo,
  c.CaseNo,
  c.InvNo,
  c.Clone                       AS CloneNo,

  -- chr 13 loss details
  l13.ChrOrd                    AS ChrOrd_13_Loss,
  l13.`Start`                   AS Start_13_Loss,
  l13.`End`                     AS End_13_Loss,

  -- chr 17 loss details
  l17.ChrOrd                    AS ChrOrd_17_Loss,
  l17.`Start`                   AS Start_17_Loss,
  l17.`End`                     AS End_17_Loss,

  -- chr 11 gain details
  g11.ChrOrd                    AS ChrOrd_11_Gain,
  g11.`Start`                   AS Start_11_Gain,
  g11.`End`                     AS End_11_Gain,

  kc.CloneShort                 AS Karyotype_Short
FROM clones_with_all_three  AS c
JOIN chr13_loss             AS l13 USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr17_loss             AS l17 USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr11_gain             AS g11 USING (RefNo, CaseNo, InvNo, Clone)
LEFT JOIN `mitelman-db.prod.KaryClone` AS kc
       ON kc.RefNo   = c.RefNo
      AND kc.CaseNo  = c.CaseNo
      AND kc.InvNo   = c.InvNo
      AND kc.CloneNo = c.Clone
ORDER BY c.RefNo, c.CaseNo, c.InvNo, c.Clone;