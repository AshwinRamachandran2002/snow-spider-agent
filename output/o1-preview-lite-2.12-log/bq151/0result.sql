WITH
  paad_patients AS (
    SELECT DISTINCT `ParticipantBarcode`
    FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
    WHERE `Study` = 'PAAD'
  ),
  high_quality_variants AS (
    SELECT 'Frame_Shift_Del' AS vc UNION ALL
    SELECT 'Frame_Shift_Ins' UNION ALL
    SELECT 'In_Frame_Del' UNION ALL
    SELECT 'In_Frame_Ins' UNION ALL
    SELECT 'Missense_Mutation' UNION ALL
    SELECT 'Nonsense_Mutation' UNION ALL
    SELECT 'Nonstop_Mutation' UNION ALL
    SELECT 'Splice_Site' UNION ALL
    SELECT 'Translation_Start_Site'
  ),
  kras_patients AS (
    SELECT DISTINCT m.`ParticipantBarcode`
    FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
    WHERE m.`Study` = 'PAAD' AND m.`Hugo_Symbol` = 'KRAS'
      AND m.`Variant_Classification` IN (SELECT vc FROM high_quality_variants)
  ),
  tp53_patients AS (
    SELECT DISTINCT m.`ParticipantBarcode`
    FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
    WHERE m.`Study` = 'PAAD' AND m.`Hugo_Symbol` = 'TP53'
      AND m.`Variant_Classification` IN (SELECT vc FROM high_quality_variants)
  ),
  patient_mutations AS (
    SELECT
      p.ParticipantBarcode,
      IF(p.ParticipantBarcode IN (SELECT ParticipantBarcode FROM kras_patients), 1, 0) AS Has_KRAS_Mutation,
      IF(p.ParticipantBarcode IN (SELECT ParticipantBarcode FROM tp53_patients), 1, 0) AS Has_TP53_Mutation
    FROM paad_patients p
  ),
  counts AS (
    SELECT
      Has_KRAS_Mutation,
      Has_TP53_Mutation,
      COUNT(*) AS observed_count
    FROM patient_mutations
    GROUP BY Has_KRAS_Mutation, Has_TP53_Mutation
  ),
  marginals AS (
    SELECT
      SUM(CASE WHEN Has_KRAS_Mutation = 1 THEN observed_count ELSE 0 END) AS total_kras_mutated,
      SUM(CASE WHEN Has_KRAS_Mutation = 0 THEN observed_count ELSE 0 END) AS total_kras_not_mutated,
      SUM(CASE WHEN Has_TP53_Mutation = 1 THEN observed_count ELSE 0 END) AS total_tp53_mutated,
      SUM(CASE WHEN Has_TP53_Mutation = 0 THEN observed_count ELSE 0 END) AS total_tp53_not_mutated,
      SUM(observed_count) AS total_patients
    FROM counts
  ),
  expected_counts AS (
    SELECT
      c.Has_KRAS_Mutation,
      c.Has_TP53_Mutation,
      c.observed_count,
      (
        (CASE WHEN c.Has_KRAS_Mutation = 1 THEN m.total_kras_mutated ELSE m.total_kras_not_mutated END) *
        (CASE WHEN c.Has_TP53_Mutation = 1 THEN m.total_tp53_mutated ELSE m.total_tp53_not_mutated END)
      ) / m.total_patients AS expected_count
    FROM counts c
    CROSS JOIN marginals m
  )
SELECT
  ROUND(
    SUM(
      ((observed_count - expected_count) * (observed_count - expected_count)) / expected_count
    ),
    4
  ) AS chi_squared_value
FROM expected_counts;