WITH
-- studies in the collection that have any T2-weighted MR series
t2_mr_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'          -- T2-weighted
),

-- studies in the collection that include segmentations of the Peripheral zone
pz_seg_studies AS (
    SELECT DISTINCT dp."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS seg
    JOIN IDC.IDC_V17.DICOM_PIVOT  dp
          ON seg."SeriesInstanceUID" = dp."SeriesInstanceUID"
    WHERE dp."collection_id" = 'qin_prostate_repeatability'
      AND seg."SegmentedPropertyType" ILIKE '%Peripheral zone%'
)

-- intersection: studies satisfying both criteria
SELECT DISTINCT t2."StudyInstanceUID"
FROM t2_mr_studies t2
JOIN pz_seg_studies pz
  ON pz."StudyInstanceUID" = t2."StudyInstanceUID"
ORDER BY t2."StudyInstanceUID";