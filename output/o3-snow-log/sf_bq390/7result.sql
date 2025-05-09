WITH t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND UPPER("Modality") = 'MR'
      AND UPPER(COALESCE("SeriesDescription", '')) LIKE '%T2%'
      AND (
           UPPER(COALESCE("SeriesDescription", '')) LIKE '%AX%'   -- axial
        OR UPPER(COALESCE("SeriesDescription", '')) LIKE '%TRA%'  -- transverse (axial) wording
      )
),
pz_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE UPPER(TO_VARCHAR("SegmentedPropertyType")) LIKE '%PERIPHERAL ZONE%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_studies t
JOIN pz_studies p
  ON t."StudyInstanceUID" = p."StudyInstanceUID"
ORDER BY t."StudyInstanceUID";