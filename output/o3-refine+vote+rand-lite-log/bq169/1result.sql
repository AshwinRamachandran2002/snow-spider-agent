WITH events AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`,
    LOWER(`Type`) AS evt_type          -- keep the original type safe from keyword conflicts
  FROM `mitelman-db.prod.CytoConverted`
),

-- (1) Loss on chr13 : 48,303,751‑48,481,890
loss13 AS (
  SELECT DISTINCT
    RefNo, CaseNo, InvNo, Clone,
    ChrOrd   AS ChrOrd13,
    `Start`  AS Start13,
    `End`    AS End13
  FROM events
  WHERE ChrOrd = 13
    AND evt_type = 'loss'
    AND NOT (`End` < 48303751 OR `Start` > 48481890)      -- range overlap test
),

-- (2) Loss on chr17 : 7,668,421‑7,687,490
loss17 AS (
  SELECT DISTINCT
    RefNo, CaseNo, InvNo, Clone,
    ChrOrd   AS ChrOrd17,
    `Start`  AS Start17,
    `End`    AS End17
  FROM events
  WHERE ChrOrd = 17
    AND evt_type = 'loss'
    AND NOT (`End` < 7668421 OR `Start` > 7687490)
),

-- (3) Gain on chr11 : 108,223,067‑108,369,102
gain11 AS (
  SELECT DISTINCT
    RefNo, CaseNo, InvNo, Clone,
    ChrOrd   AS ChrOrd11,
    `Start`  AS Start11,
    `End`    AS End11
  FROM events
  WHERE ChrOrd = 11
    AND evt_type = 'gain'
    AND NOT (`End` < 108223067 OR `Start` > 108369102)
),

-- clones that carry ALL THREE alterations
combined AS (
  SELECT
    l13.RefNo,
    l13.CaseNo,
    l13.InvNo,
    l13.Clone,
    l13.ChrOrd13,
    l13.Start13,
    l13.End13,
    l17.ChrOrd17,
    l17.Start17,
    l17.End17,
    g11.ChrOrd11,
    g11.Start11,
    g11.End11
  FROM loss13 l13
  JOIN loss17 l17
    USING (RefNo, CaseNo, InvNo, Clone)
  JOIN gain11 g11
    USING (RefNo, CaseNo, InvNo, Clone)
)

SELECT DISTINCT
  c.RefNo,
  c.CaseNo,
  c.InvNo,
  c.Clone          AS CloneNo,
  c.ChrOrd13,
  c.Start13,
  c.End13,
  c.ChrOrd17,
  c.Start17,
  c.End17,
  c.ChrOrd11,
  c.Start11,
  c.End11,
  k.CloneShort     AS KaryotypeShort
FROM combined c
LEFT JOIN `mitelman-db.prod.KaryClone` k
  ON  k.RefNo    = c.RefNo
  AND k.CaseNo   = c.CaseNo
  AND k.InvNo    = c.InvNo
  AND k.CloneNo  = c.Clone
ORDER BY
  RefNo,
  CaseNo,
  InvNo,
  CloneNo;