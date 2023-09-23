 

/* DATA EXPLORATION IN SQL*/



-- Checking that tables are imported correctly through import wizard

SELECT *
--WHERE continent is not null
FROM CovidDeaths

SELECT TOP (10)*
FROM CovidVaccinations



-- Date range for collected data on both datasets

SELECT 	MIN (Date) as FirstDate
	   ,MAX(Date) as LastDate
	  -- ,Location
FROM CovidDeaths
WHERE Continent is not null
--GROUP BY Location
ORDER BY Min(Date)


SELECT  MIN (Date) as FirstDate
	   ,MAX(Date) as LastDate
	   -- ,Location
FROM CovidVaccinations
WHERE Continent is not null
--GROUP BY Location
ORDER BY Min(Date)

/* The earliest data was collected on 1/1/2020 and the most recent was on 4/30/2021. 
   For some of the countries, numbers were not reported until several months into the pandemic, resulting in a lot of missing data. */


	  
-- Countries with the Highest infection rate


SELECT   Location
        ,Population
        ,Max(cast(total_cases as int)) as TotalCases
		,Round((Max(cast(total_cases as int))/population)*100,2) AS PercentPopInfected
FROM CovidDeaths
WHERE Continent is not null
GROUP BY Location, Population
ORDER BY PercentPopInfected desc



-- Countries with the Highest Death count 


SELECT   Location
        ,Population
        ,Max(cast(total_cases as int)) as TotalCases
		,Max(cast(total_deaths as int)) as TotalDeaths
FROM CovidDeaths
WHERE Continent is not null
GROUP BY Location, Population
ORDER BY TotalDeaths desc



-- Numbers by Continent 
-- Total reported cases and deaths (N and %) by continent as of 4/30/21

SELECT Continent
        ,Sum(new_cases) as TotalCases
		,Sum(cast(new_deaths as int)) as TotalDeaths
		,Round((Sum(cast(new_deaths as int))/Sum(new_cases))*100,2) AS Death_Percentage 
		,Round((Sum(Cast(new_cases as int))/Sum (population))*100,4) AS PercentPopInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY Continent
ORDER BY TotalDeaths desc



-- Global Numbers
-- Total reported cases and deaths worldwide as of 4/30/21

SELECT 
        Sum(cast(new_cases as int)) as TotalCases
		,Sum(cast(new_deaths as int)) as TotalDeaths
		,Round((Sum(cast(new_deaths as int))/Sum(new_cases))*100,2) AS Death_percentage 	
FROM CovidDeaths
WHERE continent is not null
--GROUP BY Location, Population
ORDER BY  TotalDeaths desc



-- Total Population Versus Vaccination


-- Percentage of population that has received at least one Covid vaccine


SELECT   dea.continent
        ,dea.location
        ,population
        ,Max(cast(people_vaccinated as int)) as PeopleVaccinated
		,Round((Max(cast(people_vaccinated as int))/population)*100,2) AS PercentPeopleVaccinated
FROM CovidDeaths AS dea
join CovidVaccinations AS vac
on dea.location =vac.location
and dea.date=vac.date
WHERE dea.continent is not null
GROUP BY dea.Continent
        ,dea.Location
        ,population


---Rolling Count of vaccinated people in the USA, CANADA and Mexico (Insert this data into a temp table)


DROP TABLE if exists #PercentPopulationVaccinated

SELECT   dea.Continent
        ,dea.Location
		,dea.Date
        ,Population
		,New_vaccinations
        ,SUM(CONVERT(int,new_vaccinations)) Over (Partition by dea.location order by dea.date) as RollingVaccinationCount
		,ROUND(SUM(CONVERT(int,new_vaccinations)) Over (Partition by dea.location order by dea.date)/population*100,2) as RollingVaccinationPct
INTO #PercentPopulationVaccinated
FROM CovidDeaths AS dea
join CovidVaccinations AS vac
on dea.location =vac.location
and dea.date=vac.date
where dea.location in ('United States','Canada','Mexico')




-- Rolling count of vaccinated people by country

-- Create View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT   dea.Continent
        ,dea.Location
		,dea.Date
        ,Population
		,New_vaccinations
        ,SUM(CONVERT(int,new_vaccinations)) Over (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount		
FROM CovidDeaths AS dea
join CovidVaccinations AS vac
on dea.location =vac.location
and dea.date=vac.date
WHERE dea.continent is not null



SELECT *
FROM PercentPopulationVaccinated
