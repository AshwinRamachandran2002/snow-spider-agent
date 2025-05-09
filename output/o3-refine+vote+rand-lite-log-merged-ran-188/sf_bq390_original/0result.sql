WITH t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'
),
seg_studies AS (
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS s
    JOIN IDC.IDC_V17.DICOM_PIVOT p
      ON s."StudyInstanceUID" = p."StudyInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND s."SegmentedPropertyType":CodeMeaning::STRING ILIKE '%peripheral%zone%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_studies t
JOIN seg_studies s
  ON t."StudyInstanceUID" = s."StudyInstanceUID";