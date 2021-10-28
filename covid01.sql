/*
Covid-19 Exploration in Microsoft SQL Server (MSSQL)

Skills Used: Aggregate Functions, Converting Data Types, Creating Views, Joins, Temp Tables, Windows Functions
*/
-- Initial exploration of the data
SELECT *
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL -- only want countries
 ORDER BY location, date


-- Refine the output from the previous query by selecting columns related to cases, deaths, and population.
SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY location, date


-- Shows the total deaths by each country and their highest death count
SELECT location, SUM(CAST(new_deaths AS INT)) total_death_count
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY total_death_count DESC


-- Let's see what is the covid death rate in the US for each day if one is infected
SELECT location, date, total_cases, total_deaths, 
       ROUND((total_deaths/total_cases)*100,2) death_percentage
  FROM PortfolioProject..CovidDeaths
 WHERE location LIKE '%states%' AND continent IS NOT NULL
 ORDER BY 1,2


-- Let's drill outwards and see the death numbers for each continent (continents are also in location column)
-- BAR CHART visual
-- Important to note that we're using new_deaths instead of total_deaths
SELECT location, SUM(CONVERT(INT, new_deaths)) total_death_count
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International')
 GROUP BY location
 ORDER BY total_death_count DESC


-- Shows the number of cases and deaths for the world in each day
SELECT date, SUM(new_cases) total_cases, SUM(CAST(new_deaths AS INT)) total_deaths,
       SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 death_percentage
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY 1,2


-- Shows the total aggregated number of deaths, cases, and percent of deaths out of global cases
-- TEXT visual (world counter for dashboard)
SELECT SUM(new_cases) total_cases, SUM(CONVERT(INT, new_deaths)) total_deaths, 
       SUM(CONVERT(INT, new_deaths))/SUM(new_cases)*100 death_percentage
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL

-----------------------------------------------------------------------

-- Now looking at infections data
-- Shows each country's total infected cases and percentage of a country's population has been infected for each day
SELECT location, date, total_cases, population,
       (total_cases/population)*100 percent_population_infected
  FROM PortfolioProject..CovidDeaths
 WHERE continent IS NOT NULL
 ORDER BY 1,2


-- Identifies the countries with the highest percentage of their population who is infected
-- MAP VISUAL
SELECT location, MAX(total_cases) highest_infection_count, population,
       MAX((total_cases/population))*100 percent_population_infected
  FROM PortfolioProject..CovidDeaths
 GROUP BY location, population
 ORDER BY percent_population_infected DESC

-----------------------------------------------------------------------

-- Taking the previous query and incorportating the date column to see which days had the highest population infection rate
-- TIME SERIES chart
SELECT location, date, MAX(total_cases) highest_infection_count, 
       population, MAX((total_cases/population))*100 percent_population_infected
  FROM PortfolioProject..CovidDeaths
 GROUP BY Location, Population, date
 ORDER BY percent_population_infected DESC

-----------------------------------------------------------------------

-- Shows the number of new vaccinations each day and how that number and percent population vaccinated adds up with each passing day.
-- Using a windows function inside a temp table
-- Temp table is more resource efficient than a subquery and more convenient for potential later uses than a CTE
-- NULL values are explained by either the vaccine has not been released yet or a country has not yet received their supply of vaccines
DROP TABLE IF EXISTS #percent_population_vaccinated GO

CREATE TABLE #percent_population_vaccinated
(continent nvarchar(255),
 location nvarchar(225),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rolling_people_vaccinated numeric)

INSERT INTO #percent_population_vaccinated
SELECT deaths.continent, deaths.location, 
       deaths.date, deaths.population, 
       vax.new_vaccinations,
       SUM(CONVERT(INT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location 
						     ORDER BY deaths.location, deaths.date) rolling_people_vaccinated
  FROM PortfolioProject..CovidDeaths deaths
  JOIN PortfolioProject..CovidVaccinations vax
    ON deaths.location = vax.location AND deaths.date = vax.date
 WHERE deaths.continent IS NOT NULL
    GO

SELECT *, (rolling_people_vaccinated/population)*100 vax_percentage
  FROM #percent_population_vaccinated
 ORDER BY 2,3
    GO


-- We can also save it into a view if we want to use this output in future queries
DROP VIEW IF EXISTS percent_population_vaccinated GO

CREATE VIEW percent_population_vaccinated AS
SELECT deaths.continent, deaths.location, 
       deaths.date, deaths.population, 
       vax.new_vaccinations,
       SUM(CONVERT(INT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location 
						     ORDER BY deaths.location, deaths.date) rolling_people_vaccinated
  FROM PortfolioProject..CovidDeaths deaths
  JOIN PortfolioProject..CovidVaccinations vax
    ON deaths.location = vax.location AND deaths.date = vax.date
 WHERE deaths.continent IS NOT NULL
    GO

SELECT *
  FROM percent_population_vaccinated
 ORDER BY location, date
