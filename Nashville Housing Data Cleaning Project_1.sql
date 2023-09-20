
/*CLEANING DATA IN SQL */

------------------------------------------------------------------------------


-- Creating temp table to clean without changing the original dataset

SELECT *
INTO #CleanNashvilleHousing
FROM NashvilleHousing



/* Convert Date format*/

ALTER TABLE #CleanNashvilleHousing
Alter column SaleDate Date;

SELECT TOP (5) *
FROM #CleanNashvilleHousing


------------------------------------------

/* Populate Property address data */

SELECT *
FROM #CleanNashvilleHousing
where PropertyAddress is null
ORDER BY ParcelID
-- 29 records will null PropertyAdress


--Joining table on itself and creating ISNULL column to test populating PropertyAddress column with inferred correct value
SELECT a. ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM #CleanNashvilleHousing a
JOIN #CleanNashvilleHousing b
on a.ParcelID= b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


-- Updating  table 
Update a
SET  PropertyAddress= ISNULL(a.PropertyAddress, b.PropertyAddress)
from #CleanNashvilleHousing a
JOIN #CleanNashvilleHousing b
on a.ParcelID= b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--Check that PropertyAddress column was updated:

SELECT *
FROM #CleanNashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID



/*Splitting PropertyAddress into separate columns */


SELECT PropertyAddress
FROM #CleanNashvilleHousing

-- Testing out Extracting the Adress and City into separate columns


SELECT
SUBSTRING (PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)as Address
,SUBSTRING (PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City
FROM #CleanNashvilleHousing

-- Creating 2 separate columns for new address and city values


ALTER TABLE #CleanNashvilleHousing
Add  PropertySplitAddress Nvarchar (255);

ALTER TABLE #CleanNashvilleHousing
Add  PropertySplitCity Nvarchar (100);

UPDATE #CleanNashvilleHousing
SET  PropertySplitAddress= SUBSTRING (PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)

UPDATE #CleanNashvilleHousing
SET  PropertySplitCity= SUBSTRING (PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))



------------------------------------------------

/* Cleaning OwnerAddress column  */


SELECT OwnerAddress
FROM #CleanNashvilleHousing


-- Testing out splitting OwnerAdress column


SELECT
PARSENAME (REPLACE(OwnerAddress,',','.'),3)as OwnerSplitAddress --Parsename starts extracting at the end of the string, so starting at 3 to get address first 
,PARSENAME (REPLACE(OwnerAddress,',','.'),2) as OwnerCity --then City
,PARSENAME (REPLACE(OwnerAddress,',','.'),1) as OwnerState -- then State
FROM #CleanNashvilleHousing


-- Creating 3 separate columns for new Address, City and State values


ALTER TABLE #CleanNashvilleHousing
Add  OwnerSplitAddress Nvarchar (255);

ALTER TABLE #CleanNashvilleHousing
Add  OwnerCity Nvarchar (100);

ALTER TABLE  #CleanNashvilleHousing
Add  OwnerState Nvarchar (3);


---Updating original table with new values


UPDATE #CleanNashvilleHousing
SET OwnerSplitAddress= PARSENAME (REPLACE(OwnerAddress,',','.'),3) 

UPDATE #CleanNashvilleHousing
SET OwnerCity= PARSENAME (REPLACE(OwnerAddress,',','.'),2)

UPDATE #CleanNashvilleHousing
SET OwnerState= PARSENAME (REPLACE(OwnerAddress,',','.'),1)



-----------------------------------------------------

/* Clean 'Sold as Vacant' column to consistent values */


SELECT DISTINCT SoldAsVacant
FROM #CleanNashvilleHousing

UPDATE #CleanNashvilleHousing
	SET SoldAsVacant= CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
	                       WHEN SoldAsVacant= 'N' THEN 'No'
						   ELSE SoldAsVacant
						   END



-----------------------------------------------------
/* Checking for duplicates */


SELECT ParcelID
      ,PropertyAddress
	  ,SaleDate
	  ,SalePrice
	  ,LegalReference
	  ,COUNT(*) as count
FROM #CleanNashvilleHousing
GROUP BY  ParcelID
      ,PropertyAddress
	  ,SaleDate
	  ,SalePrice
	  ,LegalReference
HAVING COUNT(*)>1
--- 104 duplicates found



-- Deleting Duplicates 

WITH RowNumCTE AS
   (
    SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
					   ORDER BY UniqueID) row_num
	FROM #CleanNashvilleHousing
	) 
	Delete
	FROM RowNumCTE
	WHERE row_num>1


-----------------------------------------------------

-- Deleting Unused columns


ALTER TABLE #CleanNashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress
