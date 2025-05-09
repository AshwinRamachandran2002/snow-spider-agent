-- Find all qualifying activity-pairs and enrich them with SMILES, change-class,
-- UUIDs and synthetic publication dates
WITH act_base AS (   -----------------------------------------------------------+
  -- activities that satisfy the single-record criteria                         |
  ------------------------------------------------------------------------------
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_relation,
    a.standard_value,
    a.standard_type,
    a.pchembl_value,
    a.potential_duplicate,
    CAST(cp.heavy_atoms AS INT64)            AS heavy_atoms
  FROM `bigquery-public-data.ebi_chembl.activities_30`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS cp
        ON CAST(a.molregno AS STRING) = cp.molregno
  WHERE
        CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15     -- 10–15 heavy atoms
    AND a.standard_value IS NOT NULL                       -- non-null value
    AND a.pchembl_value  > 10                              -- pChEMBL > 10
    AND a.potential_duplicate < 2                          -- < 2 duplicates
), act_filtered AS ( -----------------------------------------------------------+
  -- keep only assays / standard_type combos with < 5 total activities          |
  ------------------------------------------------------------------------------
  SELECT *
  FROM (
        SELECT
          ab.*,
          COUNT(*) OVER (PARTITION BY assay_id, standard_type) AS n_per_assay
        FROM act_base AS ab )
  WHERE n_per_assay < 5
), pairs AS (  --------------------------------------------------------------+
  -- generate all UNORDERED pairs of *different* molecules inside the same   |
  -- assay & standard_type (molregno ordering prevents reversed duplicates)  |
  ---------------------------------------------------------------------------
  SELECT
    a1.activity_id                    AS act_id_1,
    a2.activity_id                    AS act_id_2,
    a1.molregno                       AS molregno_1,
    a2.molregno                       AS molregno_2,
    a1.assay_id,
    a1.standard_type,
    SAFE_CAST(a1.standard_value AS FLOAT64) AS val1,
    SAFE_CAST(a2.standard_value AS FLOAT64) AS val2,
    a1.standard_relation              AS rel1,
    a2.standard_relation              AS rel2,
    GREATEST(a1.heavy_atoms , a2.heavy_atoms) AS max_heavy_atoms
  FROM act_filtered AS a1
  JOIN act_filtered AS a2
    ON  a1.assay_id      = a2.assay_id
    AND a1.standard_type = a2.standard_type
    AND a1.molregno      <> a2.molregno
    AND a1.molregno      <  a2.molregno          -- avoid reversed duplicates
), pairs_cls AS ( -----------------------------------------------------------+
  -- classify change direction and create UUID based on the two activity IDs  |
  ---------------------------------------------------------------------------
  SELECT
    p.*,
    CASE
      WHEN p.val1 = p.val2 THEN 'no-change'
      WHEN p.val1 < p.val2 THEN 'increase'
      ELSE                       'decrease'
    END                                                AS change_class,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(p.act_id_1,
                                     p.act_id_2))))   AS mmp_delta_uuid
  FROM pairs AS p
), pairs_smiles AS ( --------------------------------------------------------+
  -- attach canonical SMILES and derive a second UUID based on the SMILES    |
  ---------------------------------------------------------------------------
  SELECT
    pc.*,
    sm1.canonical_smiles                           AS smiles_1,
    sm2.canonical_smiles                           AS smiles_2,
    TO_HEX(MD5(TO_JSON_STRING(
         STRUCT(sm1.canonical_smiles,
                sm2.canonical_smiles))))           AS smiles_pair_uuid
  FROM pairs_cls AS pc
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` sm1
       ON sm1.molregno = CAST(pc.molregno_1 AS STRING)
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` sm2
       ON sm2.molregno = CAST(pc.molregno_2 AS STRING)
), doc_dates AS ( -----------------------------------------------------------+
  -- create synthetic publication dates for every document in docs_29        |
  ---------------------------------------------------------------------------
  SELECT
    doc_id,
    COALESCE(SAFE_CAST(year AS INT64), 1970)                               AS pub_year,
    1 + CAST(
          11 * PERCENT_RANK() OVER (
                 PARTITION BY journal,
                              COALESCE(SAFE_CAST(year AS INT64), 1970)
                 ORDER BY SAFE_CAST(first_page AS INT64) ) AS INT64)       AS pub_month,
    1 + MOD(CAST(
          308 * PERCENT_RANK() OVER (
                 PARTITION BY journal,
                              COALESCE(SAFE_CAST(year AS INT64), 1970)
                 ORDER BY SAFE_CAST(first_page AS INT64) ) AS INT64), 28)  AS pub_day
  FROM `bigquery-public-data.ebi_chembl.docs_29`
), final AS ( ---------------------------------------------------------------+
  -- arbitrarily map assay_id → doc_id (as in example queries) and enrich    |
  ---------------------------------------------------------------------------
  SELECT
    ps.act_id_1,
    ps.act_id_2,
    ps.assay_id,
    ps.standard_type,
    ps.val1,
    ps.val2,
    ps.rel1,
    ps.rel2,
    ps.max_heavy_atoms,
    ps.change_class,
    ps.mmp_delta_uuid,
    ps.smiles_pair_uuid,
    dd.pub_year,
    dd.pub_month,
    dd.pub_day,
    dd.doc_id                       AS latest_doc_id
  FROM pairs_smiles AS ps
  LEFT JOIN doc_dates AS dd
         ON CAST(ps.assay_id AS STRING) = dd.doc_id      -- demo linkage
)
SELECT *
FROM   final
ORDER  BY max_heavy_atoms DESC, act_id_1, act_id_2
LIMIT 100;