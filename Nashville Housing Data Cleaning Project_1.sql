
/*CLEANING DATA IN SQL */

------------------------------------------------------------------------------

/* Convert Date format*/

ALTER TABLE NashvilleHousing
Alter column SaleDate Date;

SELECT TOP (5) *
FROM NashvilleHousing

-- Could also have added a converted date column, then dropped the original saleDate column.

--ALTER TABLE NashvilleHousing
--Add SaleDateConverted Date;

--Update NashvilleHousing
--Set SaleDateConverted= Convert (Date, SaleDate)

--------------------------------------------------------------------------------------------

/* Populate Property address data */

SELECT *
FROM NashvilleHousing
where PropertyAddress is null
ORDER BY ParcelID
-- 29 records will null PropertyAdress


--Joining table on itself and creating ISNULL column to test populating PropertyAddress column with inferred correct value
SELECT a. ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
on a.ParcelID= b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Updating orginal table
Update a
SET  PropertyAddress= ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
JOIN NashvilleHousing b
on a.ParcelID= b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--Check that PropertyAddress column was updated:

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID


----------------------------------------------------------------------------------------

/*Breaking out address into individual columns */

SELECT PropertyAddress
FROM NashvilleHousing

-- Testing out Extracting the Adress and City into separate columns
SELECT
SUBSTRING (PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)as Address
,SUBSTRING (PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as City
FROM NashvilleHousing

-- Creating 2 separate columns for new address and city values
ALTER TABLE NashvilleHousing
Add  PropertySplitAddress Nvarchar (255);

ALTER TABLE NashvilleHousing
Add  PropertySplitCity Nvarchar (100);

UPDATE NashvilleHousing
SET  PropertySplitAddress= SUBSTRING (PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1)

UPDATE NashvilleHousing
SET  PropertySplitCity= SUBSTRING (PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

---Check for success!
SELECT TOP (5) *
FROM NashvilleHousing


-----------------------------------------------------------------------
/* Cleaning OwnerAddress column  */

SELECT OwnerAddress
FROM NashvilleHousing


-- Testing out splitting OwnerAdress column

SELECT
PARSENAME (REPLACE(OwnerAddress,',','.'),3)as OwnerSplitAddress --Parsename starts extracting at the end of the string, so starting at 3 to get address first 
,PARSENAME (REPLACE(OwnerAddress,',','.'),2) as OwnerCity --then City
,PARSENAME (REPLACE(OwnerAddress,',','.'),1) as OwnerState -- then State
FROM NashvilleHousing

-- Creating 3 separate columns for new Address, City and State values
ALTER TABLE NashvilleHousing
Add  OwnerSplitAddress Nvarchar (255);

ALTER TABLE NashvilleHousing
Add  OwnerCity Nvarchar (100);

ALTER TABLE  NashvilleHousing
Add  OwnerState Nvarchar (3);

SELECT *
FROM NashvilleHousing

---Updating original table with new values
UPDATE NashvilleHousing
SET OwnerSplitAddress= PARSENAME (REPLACE(OwnerAddress,',','.'),3) 

UPDATE NashvilleHousing
SET OwnerCity= PARSENAME (REPLACE(OwnerAddress,',','.'),2)

UPDATE NashvilleHousing
SET OwnerState= PARSENAME (REPLACE(OwnerAddress,',','.'),1)



-----------------------------------------------------------------------------
/* Clean 'Sold as Vacant' column to consistent values */

SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing

UPDATE NashvilleHousing
	SET SoldAsVacant= CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
	                       WHEN SoldAsVacant= 'N' THEN 'No'
						   ELSE SoldAsVacant
						   END

---Or this:

--UPDATE NashvilleHousing
--	SET SoldAsVacant= 'Yes' WHERE SoldAsVacant= 'Y'
--UPDATE NashvilleHousing
--	SET SoldAsVacant='No' WHERE SoldAsVacant= 'N'

SELECT SoldAsVacant, Count(*)
FROM NashvilleHousing
GROUP BY SoldAsVacant 

-----------------------------------------------------------------------------------------

/* Checking for duplicates */

SELECT ParcelID
      ,PropertyAddress
	  ,SaleDate
	  ,SalePrice
	  ,LegalReference
	  ,COUNT(*) as count
FROM NashvilleHousing
GROUP BY  ParcelID
      ,PropertyAddress
	  ,SaleDate
	  ,SalePrice
	  ,LegalReference
HAVING COUNT(*)>1
--- 104 duplicates found



---- Deleting Duplicates

WITH RowNumCTE AS
   (
    SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
					   ORDER BY UniqueID) row_num
	FROM NashvilleHousing
	) 
	Delete
	FROM RowNumCTE
	WHERE row_num>1

---Check for success

SELECT *
FROM NashvilleHousing ---104 records were deleted


-------- Deleting Unused columns

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress


----------

/*Summary Statistics */

SELECT DISTINCT YearBuilt, count(*) AS Count
from NashvilleHousing
GROUP BY YearBuilt
order by YearBuilt

SELECT YearBuiltBrackets, Count(*) AS Homes
FROM (
	SELECT *,
		CASE WHEN YearBuilt<1900 THEN 'Pre-1900'
			 WHEN YearBuilt between 1900 and 1925 THEN '1900-1925'
			 WHEN YearBuilt between 1926 and 1950 THEN '1926-1950'
			 WHEN YearBuilt between 1951 and 1975 THEN '1951-1975'
			 WHEN YearBuilt between 1976 and 2000 THEN '1976-2000'
			 WHEN YearBuilt>=2001 THEN '2001 to Date'
			 Else 'No information'
			 END as YearBuiltBrackets
	FROM NashvilleHousing
	)a
	GROUP BY YearBuiltBrackets
	ORDER BY YearBuiltBrackets