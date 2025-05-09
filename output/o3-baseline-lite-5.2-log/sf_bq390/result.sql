WITH t2_studies AS (
    SELECT DISTINCT 
        "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'
      AND "SeriesDescription" ILIKE '%AX%'          -- axial T2‑weighted series
), seg_studies AS (
    SELECT DISTINCT 
        s."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS        AS s
    JOIN IDC.IDC_V17.DICOM_PIVOT          AS p
      ON p."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND s."SegmentedPropertyType" ILIKE '%peripheral zone%'  -- anatomical structure label
)
SELECT DISTINCT 
    t."StudyInstanceUID"
FROM t2_studies t
JOIN seg_studies s
  ON s."StudyInstanceUID" = t."StudyInstanceUID"
ORDER BY 
    t."StudyInstanceUID";