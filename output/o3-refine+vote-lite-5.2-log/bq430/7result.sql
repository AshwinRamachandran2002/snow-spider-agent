/*------------------------------------------------------------
  Pairs of molecules fulfilling all requested constraints
-------------------------------------------------------------*/
WITH base_acts AS (   -- ❶ activity‑level filters
  SELECT
      a.activity_id ,
      a.assay_id ,
      a.standard_type ,
      a.standard_relation ,
      CAST(a.standard_value AS FLOAT64)   AS standard_value ,
      CAST(a.pchembl_value  AS FLOAT64)   AS pchembl_value ,
      a.molregno ,
      a.doc_id ,
      a.potential_duplicate
  FROM `bigquery-public-data.ebi_chembl.activities` a
  WHERE a.standard_value IS NOT NULL
    AND a.pchembl_value  IS NOT NULL
    AND CAST(a.pchembl_value AS FLOAT64) > 10                 -- pChEMBL > 10
),
/*----------------------------------------------------------*/
mol_desc AS (          -- ❷ molecule descriptors
  SELECT p.molregno,
         CAST(p.heavy_atoms AS INT64)       AS heavy_atoms,
         s.canonical_smiles
  FROM `bigquery-public-data.ebi_chembl.compound_properties`  p
  JOIN `bigquery-public-data.ebi_chembl.compound_structures`  s
    USING (molregno)
  WHERE p.heavy_atoms IS NOT NULL
    AND CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15        -- 10–15 heavy atoms
),
/*----------------------------------------------------------*/
acts_w_props AS (      -- ❸ attach descriptors
  SELECT b.* ,
         m.heavy_atoms ,
         m.canonical_smiles
  FROM  base_acts b
  JOIN  mol_desc  m  USING (molregno)
),
per_mol_assay AS (     -- counts within assay
  SELECT assay_id ,
         molregno ,
         COUNT(*)                                                  AS act_cnt ,
         SUM(CASE WHEN potential_duplicate='1' THEN 1 ELSE 0 END) AS dup_cnt
  FROM acts_w_props
  GROUP BY assay_id , molregno
),
good_acts AS (         -- keep scarce & non‑duplicate
  SELECT a.*
  FROM   acts_w_props a
  JOIN   per_mol_assay c
    ON   a.assay_id = c.assay_id  AND  a.molregno = c.molregno
  WHERE  c.act_cnt < 5         -- <5 activities in that assay
    AND  c.dup_cnt < 2         -- <2 duplicates
),
/*----------------------------------------------------------
   ❹ synthetic publication date
----------------------------------------------------------*/
doc_rank AS (
  SELECT
      d.doc_id ,
      COALESCE(CAST(d.year AS INT64),1970)                                   AS pub_year ,
      PERCENT_RANK() OVER (PARTITION BY d.journal, d.year
                           ORDER BY SAFE_CAST(d.first_page AS INT64))        AS prnk
  FROM  `bigquery-public-data.ebi_chembl.docs` d
),
doc_date AS (
  SELECT
      doc_id ,
      pub_year ,
      -- month 1‑12
      IFNULL( CAST(FLOOR(prnk*11) AS INT64) + 1 , 1)                         AS pub_month ,
      -- day   1‑28
      IFNULL( MOD( CAST(FLOOR(prnk*308) AS INT64) , 28) + 1 , 1)             AS pub_day ,
      FORMAT('%04d-%02d-%02d',
             pub_year,
             IFNULL( CAST(FLOOR(prnk*11)  AS INT64) + 1 , 1),
             IFNULL( MOD( CAST(FLOOR(prnk*308) AS INT64) , 28) + 1 , 1) )    AS synth_date
  FROM doc_rank
),
ready AS (             -- ❺ enrich activities with synthetic dates
  SELECT g.* ,
         d.synth_date
  FROM   good_acts g
  LEFT  JOIN doc_date d USING (doc_id)
)
/*----------------------------------------------------------
   ❻ pair different molecules within same assay & std‑type
----------------------------------------------------------*/
SELECT
    /* UUIDs generated from activity IDs and from SMILES */
    TO_HEX( MD5( TO_JSON_STRING( STRUCT(a.activity_id , b.activity_id ) ) ) )          AS uuid_activity_pair ,
    TO_HEX( MD5( TO_JSON_STRING( STRUCT(a.canonical_smiles , b.canonical_smiles) ) ) ) AS uuid_smiles_pair ,

    /* identifiers */
    a.activity_id  AS activity_id_1 ,
    b.activity_id  AS activity_id_2 ,
    a.molregno     AS molregno_1 ,
    b.molregno     AS molregno_2 ,

    /* comparison of standard values */
    a.standard_value AS std_val_1 ,
    b.standard_value AS std_val_2 ,
    CASE
        WHEN SAFE_CAST(a.standard_value AS FLOAT64) = SAFE_CAST(b.standard_value AS FLOAT64) THEN 'no-change'
        WHEN SAFE_CAST(a.standard_value AS FLOAT64)  < SAFE_CAST(b.standard_value AS FLOAT64) THEN 'increase'
        ELSE 'decrease'
    END                                                                                AS change_class ,

    /* summary columns */
    GREATEST(a.heavy_atoms , b.heavy_atoms)                                            AS max_heavy_atoms ,
    GREATEST(a.synth_date  , b.synth_date)                                             AS latest_publication_date ,
    GREATEST(CAST(a.doc_id AS INT64), CAST(b.doc_id AS INT64))                         AS highest_doc_id ,

    /* context */
    a.assay_id ,
    a.standard_type
FROM   ready a
JOIN   ready b
  ON   a.assay_id      = b.assay_id
 AND   a.standard_type = b.standard_type
 AND   a.molregno      < b.molregno                -- ensure different molecules & unique pairs
;