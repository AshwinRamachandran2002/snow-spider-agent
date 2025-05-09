/*  -----------------------------------------------------------
    Pairs of different molecules that

      • are measured in the same (assay_id , standard_type)
      • each have 10–15 heavy atoms
      • belong to an assay/-type combination that contains < 5
        activity rows in total
      • have pChEMBL > 10, non-NULL standard_value
      • have potential_duplicate < 2
    -----------------------------------------------------------
    For every unordered molecule-pair that fulfils the above
    criteria we return

      activity_id_1 , activity_id_2
      mmp_delta_uuid        – MD5 of JSON( activity_id_1 , activity_id_2 )
      smiles_pair_uuid      – MD5 of JSON( canonical_smiles_1 , _2 )
      assay_id , standard_type
      value_1 , value_2
      change_class          – increase / decrease / no-change
      max_heavy_atoms       – larger heavy-atom count of the pair
      highest_doc_id        – greatest doc_id found for the pair
      latest_publication_date – synthetic YYYY-MM-DD (see spec)
   ----------------------------------------------------------- */
WITH
/* ---------- 1. 10–15 heavy atoms ------------------------------------------ */
heavy_atoms AS (
  SELECT
    CAST(molregno AS INT64)         AS molregno_int,
    CAST(heavy_atoms AS INT64)      AS ha
  FROM `bigquery-public-data.ebi_chembl.compound_properties_29`
  WHERE CAST(heavy_atoms AS INT64) BETWEEN 10 AND 15
),

/* ---------- 2. assay/standard_type having < 5 activities ------------------ */
small_sets AS (
  SELECT assay_id, standard_type
  FROM   `bigquery-public-data.ebi_chembl.activities_30`
  GROUP  BY assay_id, standard_type
  HAVING COUNT(*) < 5
),

/* ---------- 3. candidate activity rows ----------------------------------- */
candidates AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_type,
    a.standard_value,
    a.standard_relation,
    a.pchembl_value,
    h.ha
  FROM   `bigquery-public-data.ebi_chembl.activities_30` AS a
  JOIN   small_sets                                     USING (assay_id, standard_type)
  JOIN   heavy_atoms           AS h  ON a.molregno = h.molregno_int
  WHERE  a.standard_value IS NOT NULL
    AND  a.pchembl_value  > 10
    AND  SAFE_CAST(a.potential_duplicate AS INT64) < 2
),

/* ---------- 4. build unordered molecule pairs ----------------------------- */
pairs AS (
  SELECT
    c1.activity_id            AS activity_id_1,
    c1.molregno               AS molregno_1,
    c1.standard_value         AS value_1,
    c1.standard_relation      AS rel_1,
    c1.ha                     AS ha_1,

    c2.activity_id            AS activity_id_2,
    c2.molregno               AS molregno_2,
    c2.standard_value         AS value_2,
    c2.standard_relation      AS rel_2,
    c2.ha                     AS ha_2,

    c1.assay_id,
    c1.standard_type
  FROM candidates AS c1
  JOIN candidates AS c2
    ON  c1.assay_id       = c2.assay_id
    AND c1.standard_type  = c2.standard_type
    AND c1.molregno      < c2.molregno          -- ensure unordered pairs
),

/* ---------- 5. rank documents & build synthetic publication date ---------- */
docs_ranked AS (
  WITH ranked AS (
    SELECT
      d.*,
      RANK()  OVER (PARTITION BY journal, year
                    ORDER BY COALESCE(SAFE_CAST(first_page AS INT64),0))         AS rnk,
      COUNT(*) OVER (PARTITION BY journal, year)                                 AS n_grp
    FROM `bigquery-public-data.ebi_chembl.docs_30` AS d
    WHERE year IS NOT NULL
  )
  SELECT
    doc_id,
    FORMAT(
      '%04d-%02d-%02d',
      year,
      1 + CAST(
            FLOOR( 11 * SAFE_DIVIDE(CAST(rnk - 1 AS FLOAT64),
                                     CAST(n_grp - 1 AS FLOAT64)) ) AS INT64 ),
      1 + MOD(
            CAST(
              FLOOR(308 * SAFE_DIVIDE(CAST(rnk - 1 AS FLOAT64),
                                       CAST(n_grp - 1 AS FLOAT64)) ) AS INT64 ), 28)
    ) AS synth_pubdate
  FROM ranked
)

/* ---------- 6. final result ----------------------------------------------- */
SELECT
  p.activity_id_1,
  p.activity_id_2,

  /* UUID built from the two activity IDs (unordered) */
  TO_HEX( MD5( TO_JSON_STRING( STRUCT(p.activity_id_1, p.activity_id_2) ) ) )
      AS mmp_delta_uuid,

  /* UUID built from the two canonical SMILES (unordered) */
  TO_HEX( MD5( TO_JSON_STRING(
        STRUCT(cs1.canonical_smiles, cs2.canonical_smiles) ) ) ) AS smiles_pair_uuid,

  p.assay_id,
  p.standard_type,
  p.value_1,
  p.value_2,

  CASE
      WHEN SAFE_CAST(p.value_1 AS FLOAT64) > SAFE_CAST(p.value_2 AS FLOAT64)
           THEN 'decrease'
      WHEN SAFE_CAST(p.value_1 AS FLOAT64) < SAFE_CAST(p.value_2 AS FLOAT64)
           THEN 'increase'
      ELSE 'no-change'
  END                       AS change_class,

  GREATEST(p.ha_1, p.ha_2)  AS max_heavy_atoms,

  /* highest doc_id & latest synthetic date found for either activity
     (here activity_id is naively matched onto doc_id; if no match => NULL) */
  MAX(dr.doc_id)            AS highest_doc_id,
  MAX(dr.synth_pubdate)     AS latest_publication_date

FROM pairs                  AS p
JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS cs1
     ON cs1.molregno = CAST(p.molregno_1 AS STRING)
JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS cs2
     ON cs2.molregno = CAST(p.molregno_2 AS STRING)
LEFT JOIN docs_ranked       AS dr
     ON dr.doc_id = CAST(p.activity_id_1 AS INT64)         -- illustrative link
GROUP BY
  activity_id_1, activity_id_2, mmp_delta_uuid, smiles_pair_uuid,
  assay_id, standard_type, value_1, value_2, change_class, max_heavy_atoms