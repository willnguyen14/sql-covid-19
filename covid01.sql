SELECT *
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM CovidPortfolioProject..CovidVaccinations
--WHERE continent IS NOT NULL
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, 
	   ROUND((total_deaths/total_cases)*100,2) DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2

-- Lookin at Total Cases vs Population
-- Shows what percentage of the population has gotten covid
SELECT location, date, population, total_cases,
	   (total_cases/population)*100 PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate Compared to Population
-- Not date specific, more overall
SELECT location, population, MAX(total_cases) HighestInfectionCount,
	   MAX((total_cases/population))*100 PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
-- don't want continents in output
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- let's break things down by continent
-- this might be more accurate numbers
-- figure out what's the difference between these 2 queries
--	around 35 minute mark

SELECT location, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
-- don't want continents in output
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT continent, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- showing the continents with the highest death count
-- how to look at this from the viewpoint of I'm going to 
---- visualize this

SELECT continent, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS
-- by not selecting location

SELECT date, SUM(new_cases) total_cases, SUM(CAST(new_deaths AS INT)) total_deaths,
       SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 death_percentage
FROM CovidPortfolioProject..CovidDeaths
-- WHERE location LIKE '%states%' AND 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Rolling Sum
-- everytime we get to a new location, we want the counting to start over
SELECT deaths.date, deaths.location, MAX(deaths.population) population, 
       SUM(CAST(vax.new_vaccinations AS INT)) total_vaccinations
FROM CovidPortfolioProject..CovidDeaths deaths
JOIN CovidPortfolioProject..CovidVaccinations vax
ON deaths.location = vax.location AND deaths.date = vax.date
WHERE deaths.location IS NOT NULL
GROUP BY deaths.location, deaths.date
ORDER BY 2,1




SELECT *, ROUND((rolling_people_vaccinated/population)*100, 3) vax_percentage
  FROM (SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	   	       SUM(CONVERT(INT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location 
															     ORDER BY deaths.location, deaths.date) rolling_people_vaccinated
	      FROM CovidPortfolioProject..CovidDeaths deaths
	      JOIN CovidPortfolioProject..CovidVaccinations vax
	        ON deaths.location = vax.location AND deaths.date = vax.date
         WHERE deaths.continent IS NOT NULL) subquery


-- Temp Table

DROP TABLE IF EXISTS #percent_population_vaccinated

CREATE TABLE #percent_population_vaccinated
(continent nvarchar(255),
 location nvarchar(225),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rolling_people_vaccinated numeric)

INSERT INTO #percent_population_vaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(CONVERT(INT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location 
														ORDER BY deaths.location, deaths.date) rolling_people_vaccinated
FROM CovidPortfolioProject..CovidDeaths deaths
JOIN CovidPortfolioProject..CovidVaccinations vax
ON deaths.location = vax.location AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
GO

SELECT *, (rolling_people_vaccinated/population)*100 vax_percentage
FROM #percent_population_vaccinated
ORDER BY 2,3
GO


-- CTE



-- Creating VIEW to store data for later visualizations
DROP VIEW IF EXISTS percent_population_vaccinated
GO

CREATE VIEW percent_population_vaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
	SUM(CONVERT(INT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location 
														ORDER BY deaths.location, deaths.date) rolling_people_vaccinated
FROM CovidPortfolioProject..CovidDeaths deaths
JOIN CovidPortfolioProject..CovidVaccinations vax
ON deaths.location = vax.location AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
GO

-- Can use this for the visualization later

SELECT *
FROM percent_population_vaccinated